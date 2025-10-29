import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:siparis_app/services/api_service.dart';
import 'package:siparis_app/theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool isLoading = false;
  String infoMessage = '';

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        infoMessage = 'Lütfen e-posta adresinizi girin';
      });
      return;
    }

    setState(() {
      isLoading = true;
      infoMessage = '';
    });

    try {
      final response = await _apiService.post(
        'api/auth/forgot-password', // Backenddeki tam route prefix'ine dikkat!
        {'email': email},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          infoMessage = data['message'] ?? 'E-posta gönderildi';
        });
      } else {
        setState(() {
          infoMessage =
              data['message'] ??
              'İşlem başarısız (Hata Kodu: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        infoMessage = 'Sunucuya ulaşılamadı veya bir bağlantı hatası oluştu.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      style: AppTheme.lightTheme.textTheme.bodyLarge,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.primaryColor)
            : null,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryColor),
        title: Text(
          'Şifremi Unuttum',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Şifreni sıfırlamak için e-posta adresini gir.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _emailController,
                hintText: 'E-posta adresi',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sendResetLink,
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
                          'Sıfırlama Bağlantısı Gönder',
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
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
