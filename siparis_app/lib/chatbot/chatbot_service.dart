import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:siparis_app/constants.dart';

class ChatbotService {
  // final String baseUrl;

  // ChatbotService({this.baseUrl = "${ApiConstants.baseUrl}:3000"});

  Future<String> sendMessage(String message) async {
    final url = Uri.parse("${ApiConstants.baseChatUrl}/chatbot");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? "Yanıt alınamadı.";
    } else {
      throw Exception("API hatası: ${response.statusCode}");
    }
  }
}
