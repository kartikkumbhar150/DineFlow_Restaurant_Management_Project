import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/widget_tree.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectx/views/pages/login_page.dart';   //  ADD THIS

class BusinessDetailsPage extends StatefulWidget {
  final String businessName;
  final String businessPhone;
  final String email;

  const BusinessDetailsPage({
    super.key,
    required this.businessName,
    required this.businessPhone,
    required this.email,
  });

  @override
  State<BusinessDetailsPage> createState() => _BusinessDetailsPageState();
}

class _BusinessDetailsPageState extends State<BusinessDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _fssaiController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _tableCountController = TextEditingController();

  bool _isLoading = false;
  int? _selectedGstType;

  @override
  void initState() {
    super.initState();
    _businessNameController.text = widget.businessName;
    _businessPhoneController.text = widget.businessPhone;
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _fssaiController.dispose();
    _licenseController.dispose();
    _tableCountController.dispose();
    super.dispose();
  }

  void _openApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WidgetTree()),
          (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() => _isLoading = false);
  }

  //  AUTO LOGOUT (401 par)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _submitBusinessDetails() async {
    if (!_formKey.currentState!.validate() || _selectedGstType == null) {
      _showError("Please complete all required fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _showError("Session expired. Please login again.");
        return;
      }

      final data = {
        "name": _businessNameController.text.trim(),
        "businessPhone": _businessPhoneController.text.trim(),
        "email": _emailController.text.trim(),
        "gstNumber": _gstController.text.trim(),
        "address": _addressController.text.trim(),
        "fssaiNo": _fssaiController.text.trim(),
        "licenseNo": _licenseController.text.trim(),
        "gstType": _selectedGstType,
        "tableCount":
        int.tryParse(_tableCountController.text.trim()) ?? 0,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/business'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final resJson = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          resJson['status'] == 'success') {
        businessNameNotifier.value =
            _businessNameController.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Business details saved successfully"),
          ),
        );

        _openApp();
      }

      //  TOKEN EXPIRED
      else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired — logging out")),
        );
        _logout();
      }

      // OTHER ERRORS
      else {
        _showError(resJson['message'] ?? "Failed to save details");
      }
    } catch (e) {
      _showError("Network error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // (UI unchanged)
    return Scaffold(
      // ... your existing build code ...
      // (I kept UI same — only logic changed above)
        appBar: AppBar(
          title: const Text("Business Details"),
          actions: [
            TextButton(
              onPressed: _openApp,
              child: const Text("Skip", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
        body: SafeArea(
          // rest of existing UI...
          child: Container(
            //  unchanged layout
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: _businessNameController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: "Business Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _businessPhoneController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: "Business Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _gstController,
                          decoration: const InputDecoration(
                            labelText: "GST Number",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: "Address",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _fssaiController,
                          decoration: const InputDecoration(
                            labelText: "FSSAI Number",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _licenseController,
                          decoration: const InputDecoration(
                            labelText: "License Number",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "GST Type",
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3, 4]
                              .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text("Type $e"),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedGstType = v),
                          validator: (v) =>
                          v == null ? "Select GST type" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _tableCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            labelText: "Number of Tables",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _isLoading
                            ? const CircularProgressIndicator()
                            : Row(
                          children: [
                            // SAVE BUTTON (LEFT – HALF WIDTH)
                            Expanded(
                              child: ButtonTile(
                                label: "Save",
                                onTap: _submitBusinessDetails,
                                icon: Icons.save,
                                bgColor: Colors.blue.shade700,
                                textColor: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // SKIP BUTTON (RIGHT – HALF WIDTH)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openApp,
                                icon: const Icon(Icons.skip_next),
                                label: const Text("Skip"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.blue.shade700),
                                  foregroundColor: Colors.blue.shade700,
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
