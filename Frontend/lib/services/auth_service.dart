import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/pages/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _isLoggingOut = false;

Future<void> forceLogout() async {
  if (_isLoggingOut) return;        // avoid multiple popups
  _isLoggingOut = true;

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');

  ScaffoldMessenger.of(navigatorKey.currentContext!)
      .showSnackBar(const SnackBar(
    content: Text(
      'You were logged out because your account was used on another device.',
    ),
    duration: Duration(seconds: 4),
  ));

  navigatorKey.currentState!.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
  );

  _isLoggingOut = false;
}
