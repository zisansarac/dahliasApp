import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:siparis_app/constants.dart';
import 'package:siparis_app/services/api_service.dart';
import 'package:siparis_app/theme.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool isLoading = false;
  String infoMessage = '';
  Color infoColor = Colors.red;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => infoMessage = 'Lütfen tüm alanları doldurun');
      return;
    }

    if (password != confirm) {
      setState(() => infoMessage = 'Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      isLoading = true;
      infoMessage = '';
    });

    try {
      // ⚠️ GÜNCELLEME: ApiService ve doğru endpoint kullanıldı
      final response = await _apiService.post(
        'api/auth/reset-password/${widget.token}', // Backend route'una uygun
        {'password': password},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          infoMessage = data['message'] ?? 'Şifre başarıyla sıfırlandı!';
          infoColor = Colors.green;
        });
        if (mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            // Navigator.pushReplacementNamed yerine Navigator.pushReplacement
            // çünkü yönlendirme genellikle Route ismine değil, LoginPage widget'ına yapılır.
            // Eğer /login route'unuz main.dart'ta tanımlıysa, pushReplacementNamed kullanın.
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
      } else {
        // 400 (Geçersiz token/Şifre gerekli), 403 (Süresi dolmuş) gibi hataları yakalar
        setState(() {
          infoMessage =
              data['message'] ??
              'Sıfırlama başarısız. Hata Kodu: ${response.statusCode}';
          infoColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        infoMessage = 'Sunucuya ulaşılamadı veya bir bağlantı hatası oluştu.';
        infoColor = Colors.red;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: AppTheme.lightTheme.textTheme.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.hintColor,
          ),
          onPressed: toggleVisibility,
        ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryColor),
        title: Text(
          'Şifre Sıfırlama',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Yeni Şifre',
                  obscure: _obscurePassword,
                  toggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    // 👈 Validator eklendi
                    if (value == null || value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmController,
                  hintText: 'Yeni Şifre (Tekrar)',
                  obscure: _obscureConfirm,
                  toggleVisibility: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (value) {
                    // 👈 Validator eklendi
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Şifreyi Sıfırla',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (infoMessage.isNotEmpty)
                  Text(
                    infoMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: infoColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
