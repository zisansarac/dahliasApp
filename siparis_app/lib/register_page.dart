import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:siparis_app/constants.dart'; // ApiConstants.baseUrl varsayılıyor
import 'package:siparis_app/login_page.dart';
import 'package:siparis_app/theme.dart'; // AppTheme varsayılıyor
import 'dart:convert';
import 'order_list.dart'; // OrderListPage varsayılıyor

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Form durumunu yönetmek ve doğrulamayı tetiklemek için GlobalKey
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isWomanEntrepreneur = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // 1. Form Doğrulamasını Tetikle
    if (!_formKey.currentState!.validate()) {
      setState(() => errorMessage = 'Lütfen formdaki hataları düzeltin.');
      return;
    }

    // Ek Alan Kontrolleri (Şifre Eşleşmesi)
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Şifreler eşleşmiyor.';
        isLoading = false;
      });
      return;
    }

    // Eğer doğrulama başarılıysa yükleniyor durumuna geç
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    try {
      // API isteği gövdesindeki anahtar isimleri backend ile tam eşleşmeli:
      // name, email, password, isWomanEntrepreneur
      final response = await http.post(
        // Backend'deki endpoint: router.post('/register', ...)
        Uri.parse('${ApiConstants.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          // Backend'deki key ismi: 'isWomanEntrepreneur'
          'isWomanEntrepreneur': isWomanEntrepreneur,
        }),
      );

      if (response.statusCode == 201) {
        // Kayıt başarılı: res.status(201).json({ message: 'Kayıt başarılı!' });

        // Başarılı mesajı göster (İsteğe bağlı, SnackBar daha iyi)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kayıt başarılı! Lütfen hesabınıza giriş yapınız...',
              ),
            ),
          );
        }

        // Başarılı sayfaya yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } else {
        // Backend'den gelen hata mesajını işle
        // Hata durumları: 400 (Zorunlu alan, Kullanıcı zaten kayıtlı) veya 500 (Sunucu hatası)
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          errorMessage = data['message'] ?? 'Kayıt başarısız, bilinmeyen hata.';
        });
      }
    } catch (e) {
      // Ağ hatası veya JSON decode hatası
      print('HTTP Hatası: $e'); // Konsola hata log'u düşer
      setState(() {
        errorMessage =
            'Sunucuya erişilemiyor. Lütfen ağ bağlantınızı kontrol edin.';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Yeniden kullanılan metin alanı oluşturucu metodu.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator, // Doğrulama eklendi
    bool obscure = false,
    IconData? icon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text, // Klavye tipi eklendi
  }) {
    return TextFormField(
      // TextField yerine TextFormField kullanıldı
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator, // Validator eklendi
      style: AppTheme.lightTheme.textTheme.bodyLarge,
      decoration: InputDecoration(
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.primaryColor)
            : null,
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: AppTheme.lightTheme.textTheme.bodyMedium,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: AppTheme.inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: AppTheme.inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          // Hata durumunda border
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Hata ve focus durumunda border
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Form(
                      // Form widget'ı eklendi
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hesabını oluştur",
                            style: AppTheme.lightTheme.textTheme.displayLarge
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hemen kaydol ve siparişlerini rahatça yönet.",
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),

                          // Kullanıcı Adı
                          _buildTextField(
                            controller: _nameController,
                            hintText: 'Kullanıcı Adı',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kullanıcı adı boş olamaz.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // E-posta
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'E-posta',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'E-posta boş olamaz.';
                              }
                              // Basit bir e-posta formatı kontrolü
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'Geçerli bir e-posta adresi girin.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Şifre
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'Şifre',
                            obscure: _obscurePassword,
                            icon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre boş olamaz.';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalıdır.';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.hintColor,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Şifre Tekrarı
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Şifreyi Tekrar Gir',
                            obscure: _obscureConfirmPassword,
                            icon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre tekrarı boş olamaz.';
                              }
                              if (value != _passwordController.text) {
                                return 'Şifreler eşleşmiyor.';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.hintColor,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Kadın Girişimci Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: isWomanEntrepreneur,
                                onChanged: (value) {
                                  setState(
                                    () => isWomanEntrepreneur = value ?? false,
                                  );
                                },
                                fillColor: WidgetStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppTheme.primaryColor;
                                  }
                                  return AppTheme
                                      .inputBorderColor; // Daha belirgin bir renk kullanılabilir
                                }),
                                checkColor: Colors.white,
                              ),
                              Text(
                                "Kadın girişimciyim.",
                                style: AppTheme.lightTheme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Hata Mesajı (Daha belirgin hale getirildi)
                          if (errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                errorMessage,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),

                          // Kayıt Ol Butonu
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius,
                                  ),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      "Kayıt Ol",
                                      style: AppTheme
                                          .lightTheme
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Giriş Yap Yönlendirmesi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Zaten hesabın var mı? ",
                                style: AppTheme.lightTheme.textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login', // Giriş Sayfası rotası varsayılıyor
                                  );
                                },
                                child: Text(
                                  "Giriş Yap",
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
