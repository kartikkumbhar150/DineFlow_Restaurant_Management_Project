import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:convert';
import 'dart:io';
import 'package:file_saver/file_saver.dart'; 
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ExcelBulkUploadPage extends StatefulWidget {
  const ExcelBulkUploadPage({super.key});

  @override
  State<ExcelBulkUploadPage> createState() => _ExcelBulkUploadPageState();
}

class _ExcelBulkUploadPageState extends State<ExcelBulkUploadPage> {
  File? _selectedFile;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _parsedItems = [];
  String? _fileName;

  // Sample data for template generation
  final List<Map<String, dynamic>> _sampleData = [
    {'item': 'Chocolate Cake', 'price': 250.0, 'category': 'Desserts'},
    {'item': 'Masala Dosa', 'price': 120.0, 'category': 'Main Course'},
    {'item': 'Green Tea', 'price': 50.0, 'category': 'Beverages'},
    {'item': 'Paneer Tikka', 'price': 180.0, 'category': 'Starters'},
  ];
  //
  Future<void> _downloadCurrentProducts() async {
    try {
      setState(() => _isProcessing = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final url = AppConfig.backendUrl;

      final response = await http.get(
        Uri.parse('$url/api/v1/products/export/xlsx'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // SAME BEHAVIOUR as template/sample
        final dir = await FilePicker.platform.getDirectoryPath();

        if (dir != null) {
          final file = File("$dir/current_products.xlsx");
          await file.writeAsBytes(bytes);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("File saved at: ${file.path}"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Save cancelled."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(
            "Failed ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error downloading file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  //
  Future<void> _downloadTemplate({bool withSamples = false}) async {
  try {
    // Create Excel file
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
        excel_lib.TextCellValue('item');
    sheet.cell(excel_lib.CellIndex.indexByString('B1')).value =
        excel_lib.TextCellValue('price');
    sheet.cell(excel_lib.CellIndex.indexByString('C1')).value =
        excel_lib.TextCellValue('category');

    // Style headers
    for (int col = 0; col < 3; col++) {
      final cell = sheet.cell(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = excel_lib.CellStyle(bold: true);
    }

    // Add sample data if requested
    if (withSamples) {
      for (int i = 0; i < _sampleData.length; i++) {
        final rowIndex = i + 1;
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = excel_lib.TextCellValue(_sampleData[i]['item']);
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = excel_lib.DoubleCellValue(_sampleData[i]['price']);
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = excel_lib.TextCellValue(_sampleData[i]['category']);
      }
    }

    // Encode file
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file.');

    final fileName = withSamples ? 'items_sample.xlsx' : 'items_template.xlsx';

    // Let user choose folder to save file
    final outputDir = await FilePicker.platform.getDirectoryPath();

    if (outputDir != null) {
      final filePath = '$outputDir/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved at: $filePath'),
          backgroundColor: Colors.blue.shade500,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Save cancelled.'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error creating file: $e'),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }
}


  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _parsedItems.clear();
        });
        await _parseExcelFile();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _parseExcelFile() async {
    if (_selectedFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);
      
      final sheet = excel.tables.values.first;
      final List<Map<String, dynamic>> items = [];
      
      // Skip header row (index 0)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        
        // Ensure row and its cells are not null and have enough columns
        if (row.length >= 3 && row[0]?.value != null && row[1]?.value != null && row[2]?.value != null) {
            final item = row[0]!.value.toString().trim();
            final priceStr = row[1]!.value.toString().trim();
            final category = row[2]!.value.toString().trim();

            if (item.isNotEmpty && priceStr.isNotEmpty && category.isNotEmpty) {
                final price = double.tryParse(priceStr);
                if (price != null && price > 0) {
                    items.add({
                        'name': item,
                        'price': price,
                        'category': category,
                    });
                }
            }
        }
      }
      
      if (!mounted) return;
      setState(() => _parsedItems = items);
      
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No valid items found in the Excel file.'),
            backgroundColor: Colors.orange.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing Excel file: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _uploadItems() async {
    if (_parsedItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final url = AppConfig.backendUrl;
      final response = await http.post(
        Uri.parse('$url/api/v1/products/bulk/save'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_parsedItems),
      );
      
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_parsedItems.length} items uploaded successfully!'),
            backgroundColor: Colors.blue.shade500,
          ),
        );
        
        setState(() {
          _selectedFile = null;
          _fileName = null;
          _parsedItems.clear();
        });
        
        Navigator.pop(context, true);
      } else {
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading items: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemPreview(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              item['name'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              item['category'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${item['price'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Bulk Upload Items',
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Items via Excel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload multiple items at once using an Excel file with columns: item, price, category.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Step 1: Download Templates
              Text(
                'Step 1: Download Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                title: 'Download Blank Template',
                subtitle: 'Get blank Excel template with correct format.',
                icon: Icons.download_rounded,
                onTap: () => _downloadTemplate(withSamples: false),
                color: Colors.blue.shade600,
              ),

              _buildActionButton(
                title: 'Download Sample File',
                subtitle: 'Get template with sample data for reference.',
                icon: Icons.file_download_rounded,
                onTap: () => _downloadTemplate(withSamples: true),
                color: Colors.green.shade600,
              ),
              _buildActionButton(
                title: 'Download Current Products',
                subtitle: 'Download all items with item, price & category from your current menu.',
                icon: Icons.file_download_rounded,
                onTap: _downloadCurrentProducts,
                color: Colors.purple.shade600,
              ),


              const SizedBox(height: 24),

              // Step 2: Upload File
              Text(
                'Step 2: Upload Excel File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                title: _fileName ?? 'Select Excel File',
                subtitle: _fileName != null
                    ? 'File selected - tap to change'
                    : 'Choose .xlsx or .xls file from your device.',
                icon: Icons.upload_file_rounded,
                onTap: _pickFile,
                color: Colors.orange.shade600,
              ),

              if (_isProcessing && _parsedItems.isEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Processing Excel file...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Step 3: Preview and Upload
              if (_parsedItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Step 3: Review & Upload',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_parsedItems.length} items found and ready to upload',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items Preview
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _parsedItems.length,
                          itemBuilder: (context, index) {
                            return _buildItemPreview(_parsedItems[index], index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Upload Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade500,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade500.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _isProcessing ? null : _uploadItems,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.cloud_upload_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            const SizedBox(width: 12),
                            Text(
                              _isProcessing
                                  ? 'Uploading Items...'
                                  : 'Upload ${_parsedItems.length} Items',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.orange.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Download the template Excel file.\n'
                      '2. Fill in your items with: item name, price, category.\n'
                      '3. Save the file and upload it here.\n'
                      '4. Review the parsed items and upload to your inventory.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}