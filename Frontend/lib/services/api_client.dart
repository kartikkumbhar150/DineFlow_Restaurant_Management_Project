import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'auth_service.dart';

Future<Map<String, String>> _headers() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

Future<http.Response> authGet(String path) async {
  final response = await http.get(
    Uri.parse('${AppConfig.backendUrl}$path'),
    headers: await _headers(),
  );

  if (response.statusCode == 401) await forceLogout();
  return response;
}

Future<http.Response> authPost(String path, dynamic body) async {
  final response = await http.post(
    Uri.parse('${AppConfig.backendUrl}$path'),
    headers: await _headers(),
    body: jsonEncode(body),
  );

  if (response.statusCode == 401) await forceLogout();
  return response;
}

Future<http.Response> authPut(String path, dynamic body) async {
  final response = await http.put(
    Uri.parse('${AppConfig.backendUrl}$path'),
    headers: await _headers(),
    body: jsonEncode(body),
  );

  if (response.statusCode == 401) await forceLogout();
  return response;
}

Future<http.Response> authDelete(String path) async {
  final response = await http.delete(
    Uri.parse('${AppConfig.backendUrl}$path'),
    headers: await _headers(),
  );

  if (response.statusCode == 401) await forceLogout();
  return response;
}
Future<http.StreamedResponse> authMultipart(
    String path,
    http.MultipartRequest request,
    ) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Content-Type'] = 'multipart/form-data';

  final response = await request.send();

  // IMPORTANT — 401 means force logout
  if (response.statusCode == 401) {
    await forceLogout();
  }

  return response;
}
