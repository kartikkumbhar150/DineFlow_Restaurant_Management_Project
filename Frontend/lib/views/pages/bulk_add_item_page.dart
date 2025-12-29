import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verify_items_page.dart';
import 'package:projectx/services/api_client.dart';
import 'package:projectx/utils/logout.dart';


class BulkAddItemPage extends StatefulWidget {
  const BulkAddItemPage({super.key});

  @override
  State<BulkAddItemPage> createState() => _BulkAddItemPageState();
}

class _BulkAddItemPageState extends State<BulkAddItemPage> {
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${AppConfig.backendUrl}/api/v1/products/bulk/upload"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("file", _selectedImage!.path),
      );

      final response = await authMultipart(
        "/api/v1/products/bulk/upload",
        request,
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);

        if (decoded["status"] == "success" && decoded["data"] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyItemsPage(
                items: List<Map<String, dynamic>>.from(decoded["data"]),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No items returned from server"),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }

      else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired — logging out")),
        );
        await forceLogout();
      }

      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: ${response.statusCode}"),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Bulk Add Items",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload Menu Image",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Select an image of your menu to automatically extract items and prices",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 32),

              // Image Preview Container
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No image selected",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Choose a clear image of your menu",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Pick Image Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Colors.blue.shade500.withValues(alpha: 0.2),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.photo_library_rounded,
                              size: 22,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Pick Menu Image",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 24,
                            color: Colors.grey.shade800.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Upload Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _selectedImage == null
                      ? Colors.grey.shade300
                      : Colors.blue.shade500,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedImage != null ? [
                    BoxShadow(
                      color: Colors.blue.shade500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: (_isUploading || _selectedImage == null) ? null : _uploadImage,
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isUploading
                                ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Icon(
                              Icons.cloud_upload_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _isUploading ? "Uploading..." : "Upload & Process",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (!_isUploading)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_selectedImage == null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Please select an image first to enable upload",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                      ),
                      const SizedBox(height: 12,),
                      Text(
                        "Instructions:\n"
                            "1) Use .jpg images only\n"
                            "2) Max size of image is 10 mb",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),


              ],

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}