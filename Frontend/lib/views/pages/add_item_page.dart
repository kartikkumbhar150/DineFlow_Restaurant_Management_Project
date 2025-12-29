import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'dart:convert';
import 'package:projectx/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectx/utils/logout.dart';  //  ADD THIS

class AddItemPage extends StatefulWidget {
  final List<String> categories;

  const AddItemPage({super.key, required this.categories});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _customCategoryController =
  TextEditingController();

  String? selectedCategory;
  bool isSubmitting = false;
  bool isCustomCategory = false;

  // AUTO LOGOUT (401 par)


  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final category =
    isCustomCategory ? _customCategoryController.text.trim() : selectedCategory ?? '';

    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid price")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await authPost(
        '/api/v1/products',
        {
          "name": name,
          "description": description,
          "price": price,
          "category": category,
          "subCategory": category,
          "imageUrl": ""
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      }

      // TOKEN EXPIRED
      else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired — logging out")),
        );
        await forceLogout();
      }

      // OTHER ERRORS
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add item: ${response.statusCode}"),
          ),
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
        title: const Text('Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter item name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  final p = double.tryParse(val ?? '');
                  if (p == null || p <= 0) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                hint: const Text('Select Category'),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                    isCustomCategory = value == 'Other';
                  });
                },
                items: [
                  ...widget.categories.map(
                        (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other (Enter new category)'),
                  ),
                ],
                validator: (value) {
                  if (value == null ||
                      (value == 'Other' &&
                          _customCategoryController.text.trim().isEmpty)) {
                    return 'Please provide a category';
                  }
                  return null;
                },
              ),

              if (isCustomCategory) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customCategoryController,
                  decoration:
                  const InputDecoration(labelText: 'Custom Category'),
                  validator: (val) =>
                  val == null || val.trim().isEmpty
                      ? 'Enter category'
                      : null,
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: Text(isSubmitting ? "Submitting..." : "Submit"),
                onPressed: isSubmitting ? null : _submitItem,
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
