import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projectx/config.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/views/widget_tree.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';
import 'services/api_client.dart';

// GLOBAL navigator key (used for forceLogout everywhere)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginAndFetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) return false;

    final response = await authGet('/api/v1/business/dashboard/showMe');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'];

      businessNameNotifier.value = data['businessName'];
      businessLogoNotifier.value = data["logoUrl"];
      roleNotifier.value = data['role'];
      userPhoneNotifier.value = data['username'];

      return true;
    } else {
      await prefs.remove('auth_token');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,   // now valid
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
      ),
      home: FutureBuilder<bool>(
        future: checkLoginAndFetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return const WidgetTree();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
