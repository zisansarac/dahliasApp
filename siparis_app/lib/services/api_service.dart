import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:flutter/material.dart';

class ApiService {
  Future<String?> _getAccessToken() async {
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

  /// Token’ı yenile
  Future<bool> _refreshToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;

    // Backend'inizdeki refresh endpoint'i /api/auth/refresh (veya benzeri)
    final refreshUrl = Uri.parse('${ApiConstants.baseUrl}/api/auth/refresh');

    final response = await http.post(
      refreshUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveTokens(
        data['access_token'],
        refreshToken: data['refresh_token'],
      );
      return true;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return false;
    }
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // -------------------------------------------------------------
  // Yardımcı Metot: Güvenli URL Oluşturma
  // -------------------------------------------------------------

  String _buildUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }

    // Base URL'i al ve sondaki '/' işaretini kaldır
    String baseUrl = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;

    // Endpoint'in başındaki '/' işaretini kaldır
    String cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    // Güvenli birleştirme
    return '$baseUrl/$cleanEndpoint';
  }

  /// GET isteği
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse(_buildUrl(endpoint));

    String? token = await _getAccessToken();
    var response = await http.get(url, headers: _headers(token));

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getAccessToken();
        response = await http.get(url, headers: _headers(token));
      }
    }

    return response;
  }

  /// POST isteği
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse(_buildUrl(endpoint));

    String? token = await _getAccessToken();
    var response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getAccessToken();
        response = await http.post(
          url,
          headers: _headers(token),
          body: jsonEncode(body),
        );
      }
    }

    return response;
  }

  // -------------------------------------------------------------
  // YENİ: PUT İsteği
  // -------------------------------------------------------------

  /// PUT isteği
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse(_buildUrl(endpoint));

    String? token = await _getAccessToken();
    var response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getAccessToken();
        response = await http.put(
          url,
          headers: _headers(token),
          body: jsonEncode(body),
        );
      }
    }

    return response;
  }

  // -------------------------------------------------------------
  // YENİ: DELETE İsteği
  // -------------------------------------------------------------

  /// DELETE isteği (Body olmadan)
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse(_buildUrl(endpoint));

    String? token = await _getAccessToken();
    var response = await http.delete(url, headers: _headers(token));

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        token = await _getAccessToken();
        response = await http.delete(url, headers: _headers(token));
      }
    }

    return response;
  }
}
