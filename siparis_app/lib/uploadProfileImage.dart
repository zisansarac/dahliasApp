import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siparis_app/constants.dart';
import 'dart:convert'; // Hata mesajlarını çözmek için

Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
  final prefs = await SharedPreferences.getInstance();
  // Token anahtarının 'access_token' olduğunu varsayıyoruz (önceki ProfilePage kodunuzdan).
  final token = prefs.getString('access_token');
  if (token == null) {
    throw Exception('Oturum token\'ı bulunamadı. Lütfen tekrar giriş yapın.');
  }

  // ⚡ KRİTİK DÜZELTME: Backend PUT beklediği için metodu PUT olarak ayarlıyoruz.
  final uri = Uri.parse('${ApiConstants.baseUrl}/api/user/update-profile');
  final request = http.MultipartRequest('PUT', uri);

  request.headers['Authorization'] = 'Bearer $token';

  // Metin alanlarını boş da olsa ekleyelim (name ve bio).
  // Bu, sadece resim güncellense bile backend'in update mantığı için önemlidir.
  // Varsayım: name ve bio düzenlenmediyse mevcut değerleri gönderilmelidir.
  // Bu örnekte sadece resim gönderimi yapılıyor, diğer alanlar boş gönderilebilir veya hiç gönderilmeyebilir.
  // Backend'de boş alanlar esnek olduğu için sadece resmi gönderiyoruz.

  request.files.add(
    await http.MultipartFile.fromPath(
      'profile_image', // Backend'in beklediği anahtar
      imageFile.path,
      filename: basename(imageFile.path),
    ),
  );

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  final resStr = utf8.decode(response.bodyBytes);

  if (response.statusCode == 200) {
    print('✅ Profil fotoğrafı başarıyla yüklendi. Cevap: $resStr');
    return json.decode(resStr); // Güncel kullanıcı verilerini döndür
  } else if (response.statusCode == 400) {
    // Backend'den gelen 400 hatası (Örn: 'Güncellenecek veri yok')
    final errorData = json.decode(resStr);
    throw Exception(errorData['error'] ?? 'Geçersiz istek.');
  } else if (response.statusCode == 401) {
    throw Exception('Yetkilendirme hatası. Token süresi dolmuş olabilir.');
  } else {
    print('❌ Hata kodu: ${response.statusCode}');
    throw Exception('Sunucu hatası (${response.statusCode}): $resStr');
  }
}
