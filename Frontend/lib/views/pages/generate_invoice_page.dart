import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/invoice_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GenerateInvoicePage extends StatefulWidget {
  final int tableNumber;

  const GenerateInvoicePage({super.key, required this.tableNumber});

  @override
  State<GenerateInvoicePage> createState() => _GenerateInvoicePageState();
}

class _GenerateInvoicePageState extends State<GenerateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isSubmitting = false;

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => isSubmitting = true);

    try {
      final url = AppConfig.backendUrl;
      final response = await http.post(
        Uri.parse('$url/api/v1/invoices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "customerName": name,
          "customerPhoneNo": phone,
          "tableNumber": widget.tableNumber,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final invoiceId = responseData['data']['invoiceNumber'];

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => InvoicePage(invoiceId: invoiceId),
          ),
              (route) => route.isFirst,   // keep only the first (home) route
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to generate invoice: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // CUSTOMER NAME INPUT
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter customer name' : null,
              ),
              const SizedBox(height: 16),

              // PHONE NUMBER INPUT
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return null;
                  }
                  if (val.length < 10) {
                    return 'Enter valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: Text(isSubmitting ? "Submitting..." : "Submit"),
                onPressed: isSubmitting ? null : _generateInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
