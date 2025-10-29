class ApiConstants {
  static const String baseUrl = "http://192.168.0.22:3000";
  static const String baseChatUrl = "http://192.168.0.22:5000";

  static const String login = "$baseUrl/api/auth/login";
  static const String register = "$baseUrl/register";
  static const String orders = "$baseUrl/api/orders";
  static const String forgotPassword = "$baseUrl/api/auth/forgot-password";
  static const String resetPassword = "$baseUrl/api/auth/reset-password";
  static const String womenMap = "$baseUrl/api/women-map";
  static const String refresh = "$baseUrl/api/auth/refresh"; // <-- düzeltildi
}
