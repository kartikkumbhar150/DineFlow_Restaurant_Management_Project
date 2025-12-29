import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/main.dart';

Future<void> forceLogout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');

  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
  );
}
