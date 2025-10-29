import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:siparis_app/theme.dart';
import 'package:siparis_app/constants.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _profileImage;
  String? _profileImageUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(String accessToken, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      String? token = await _getToken();
      if (token == null) return _redirectToLogin();

      final success = await _fetchUserProfile(token);
      if (!success) {
        // Eğer 401 aldıysak refresh token ile dene
        final refreshToken = await _getRefreshToken();
        if (refreshToken != null) {
          final refreshed = await _refreshAccessToken(refreshToken);
          if (refreshed != null) {
            token = refreshed;
            final retry = await _fetchUserProfile(token);
            if (!retry) _redirectToLogin();
          } else {
            _redirectToLogin();
          }
        } else {
          _redirectToLogin();
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<bool> _fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final prefs = await SharedPreferences.getInstance();

        // Backend'den gelen anahtar: profile_image_url
        String? profileImageUrl = data['profile_image_url'];

        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          await prefs.setString('profile_image_url', profileImageUrl);
        } else {
          await prefs.remove('profile_image_url');
        }

        if (mounted) {
          setState(() {
            _profileImageUrl = profileImageUrl;
            _emailController.text = data['email'] ?? '';
            // FIX: 'username' yerine backend'in gönderdiği 'name' alanını kullan
            _nameController.text = data['name'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _profileImage = null;
          });
        }
        return true;
      } else if (response.statusCode == 401) {
        // token geçersiz
        return false;
      } else {
        throw Exception('Profil verisi alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil yüklenirken hata: $e')));
      }
      return false;
    }
  }

  Future<String?> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];
        await _saveTokens(accessToken, refreshToken: newRefreshToken);
        return accessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserProfile() async {
    setState(() => _loading = true);
    try {
      String? token = await _getToken();
      if (token == null) return _redirectToLogin();

      // CRITICAL FIX 1: HTTP metodu POST yerine PUT olmalı
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/user/update-profile');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // CRITICAL FIX 2: 'username' yerine backend'in beklediği 'name' alanı kullanılmalı
      request.fields['email'] = _emailController.text.trim();
      request.fields['name'] = _nameController.text.trim();
      request.fields['bio'] = _bioController.text.trim();

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image', // Backend'deki multer alan adı
            _profileImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final resData = json.decode(utf8.decode(response.bodyBytes));

        // Backend, güncel kullanıcıyı 'user' objesi içinde döndürüyor.
        final updatedUser = resData['user'];

        if (updatedUser != null && updatedUser['profile_image_url'] != null) {
          final newImageUrl = updatedUser['profile_image_url'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_url', newImageUrl);
          if (mounted) {
            setState(() {
              _profileImageUrl = newImageUrl;
              _profileImage = null;
            });
          }
        }

        // Güncel veriyi çekmek için tüm profili yeniden yükle
        await _loadProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi')),
          );
        }
      } else if (response.statusCode == 401) {
        // Access token süresi dolmuş olabilir, refresh deneyelim
        final refreshToken = await _getRefreshToken();
        if (refreshToken != null) {
          final newToken = await _refreshAccessToken(refreshToken);
          if (newToken != null) {
            await _saveUserProfile(); // Retry
            return;
          }
        }
        _redirectToLogin();
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(
          'Profil güncellenemedi: ${errorData['error'] ?? 'Bilinmeyen Hata'}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil kaydedilirken hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
        _profileImageUrl = null;
      });
    }
  }

  ImageProvider _getImageProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      String imageUrl = _profileImageUrl!;

      // Eğer URL tam değilse, base URL'yi ekle
      if (!imageUrl.startsWith('http')) {
        final baseUrl = ApiConstants.baseUrl.endsWith('/')
            ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
            : ApiConstants.baseUrl;
        // Backend'in döndürdüğü 'profile_images/...' yolu için tam URL'yi oluşturur.
        imageUrl = '$baseUrl/$imageUrl';
      }

      // Cache sorununu çözmek için timestamp ekleyelim
      return NetworkImage(
        '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
        scale: 0.8,
      );
    }

    return const AssetImage("assets/images/avatar.jpg");
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium,
        prefixIcon: Icon(icon, color: theme.iconTheme.color),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Profilim",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _getImageProvider(),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              backgroundColor: theme.primaryColor,
                              radius: 16,
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // E-posta alanı, genellikle sadece okunur
                    _buildTextField(
                      label: "Email Adresim",
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    // Kullanıcı Adı (Name) alanı, düzenlenebilir olmalı
                    _buildTextField(
                      label: "Kullanıcı Adım (İsim)",
                      controller: _nameController,
                      icon: Icons.person_outline,
                      readOnly: false, // Düzenlenebilir yapıldı
                    ),
                    const SizedBox(height: 16),
                    // Biyografi alanı, düzenlenebilir olmalı
                    _buildTextField(
                      label: "Biyografim",
                      controller: _bioController,
                      icon: Icons.info_outline,
                      maxLines: 4,
                      readOnly: false, // Varsayılan olarak düzenlenebilir
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Kaydet",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
