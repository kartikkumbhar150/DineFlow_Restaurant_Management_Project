import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/pages/business_details_page.dart';
import 'package:projectx/views/pages/phone_verify_page.dart';
import 'package:projectx/views/widget_tree.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final String? businessName;
  final String? businessPhone;
  final String? email;

  const LoginPage({
    super.key,
    this.businessName,
    this.businessPhone,
    this.email,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _backendMessage;
  // final String _backendBaseUrl = '$url/api/v1';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> fetchAndStoreUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) return false;

    final url = AppConfig.backendUrl;
    final response = await http.get(
      Uri.parse('$url/api/v1/business/dashboard/showMe'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'];

      businessNameNotifier.value = data['businessName'];
      businessLogoNotifier.value = data['logoUrl'];
      roleNotifier.value = data['role'];
      userPhoneNotifier.value = data['username'];

      //  ADD THESE LINES
      await prefs.setString('user_role', data['role']);

      return true;
    }

    return false;
  }


  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _backendMessage = null;
    });
    final url = AppConfig.backendUrl;
    final Uri urlBackend = Uri.parse('$url/api/v1/auth/login');

    try {
      final response = await http.post(
        urlBackend,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        setState(() {
          _backendMessage = json['message'] ?? "Login successful!";
        });

        await saveToken(json['data']);

        // Fetch user data BEFORE navigating
        bool ok = await fetchAndStoreUserData();

        if (!ok) {
          setState(() {
            _backendMessage = "Failed to load user data.";
          });
          return;
        }

        if (!mounted) return;

        // If user came from business registration
        if (widget.businessName != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessDetailsPage(
                businessName: widget.businessName!,
                businessPhone: widget.businessPhone!,
                email: widget.email!,
              ),
            ),
          );
        } else {
          // NORMAL LOGIN FLOW → GO DIRECTLY TO WIDGET TREE
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WidgetTree()),
          );
        }
      }
      else {
        //  NEW PART
        setState(() {
          _backendMessage =
          (json['message']?.toString().toLowerCase().contains("invalid") ??
              false)
              ? "Invalid credentials"
              : "Invalid credentials";
        });
      }
    } catch (e) {
      setState(() {
        _backendMessage = "Network error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.blue.shade400,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade800,
                    offset: const Offset(0, 3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Login", style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 16),
                      Text(
                        "Sign in with credentials",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          // Country code field
                          SizedBox(
                            width: 40,
                            child: Text("+91", textAlign: TextAlign.right),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                hintText: "Enter your phone number",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a phone number';
                                }
                                if (value.length != 10) {
                                  return 'Phone number must be 10 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneVerifyPage(isReset: true),
                              ),
                            );
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        ButtonTile(
                          label: "Login",
                          onTap: _submitLogin,
                          icon: Icons.login_rounded,
                          bgColor: Colors.blue.shade700,
                          textColor: Colors.white,
                        ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhoneVerifyPage(),
                            ),
                          );
                        },
                        child: Text("New User? Register here"),
                      ),

                      if (_backendMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _backendMessage!,
                            style: TextStyle(
                              color:
                                  _backendMessage!.toLowerCase().contains(
                                    'success',
                                  )
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
