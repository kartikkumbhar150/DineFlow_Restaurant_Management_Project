import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/services/expense_report_pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExpenseReportPage extends StatefulWidget {
  const ExpenseReportPage({super.key});

  @override
  State<ExpenseReportPage> createState() => _ExpenseReportPageState();
}

class _ExpenseReportPageState extends State<ExpenseReportPage> {
  List<dynamic> _inventoryData = [];
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    _selectedDateRange = DateTimeRange(start: firstDay, end: now);
    _fetchExpenseReport();
  }

  Future<void> _fetchExpenseReport() async {
    if (_selectedDateRange == null) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final body = {
      "startDate": _selectedDateRange!.start.toIso8601String().split('T')[0],
      "endDate": _selectedDateRange!.end.toIso8601String().split('T')[0],
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/report/inventory'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final total = data.fold<double>(
          0,
              (sum, item) => sum + (item['price'] as num).toDouble(),
        );

        setState(() {
          _inventoryData = data;
          _totalExpense = total;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load expense report');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading expense report: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.red.shade600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchExpenseReport();
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _inventoryData.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['itemName'], style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(item['quantity'].toString())),
              DataCell(Text(item['unit'])),
              DataCell(Text('₹${item['price']}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold))),
              DataCell(Text(item['date'])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Expense Report",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: Colors.grey.shade800),
            onPressed: _inventoryData.isEmpty
                ? null
                : () => ExpenseReportPdfGenerator.generateAndShare(
              _inventoryData,
              _totalExpense,
              _selectedDateRange!,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade800),
            onPressed: _fetchExpenseReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Expense Analytics",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800, letterSpacing: 0.5),
            ),
            const SizedBox(height: 24),

            // Date Range Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showDateRangePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.date_range_rounded, color: Colors.red.shade600, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Report Period", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              Text(
                                "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: CircularProgressIndicator()))
            else ...[
              Text(
                "Key Metrics",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total Expense",
                      "₹${_totalExpense.toStringAsFixed(2)}",
                      Icons.payments_rounded,
                      Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Items Count",
                      "${_inventoryData.length}",
                      Icons.inventory_2_rounded,
                      Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Inventory Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),
              if (_inventoryData.isNotEmpty)
                _buildTableContainer()
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text("No data for selected period", style: TextStyle(color: Colors.grey.shade400)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}