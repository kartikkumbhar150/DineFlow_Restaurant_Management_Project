import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/services/sales_report_pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;


  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _selectedDateRange = DateTimeRange(start: firstDayOfMonth, end: now);
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    if (_selectedDateRange == null) return;

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final startDate = _selectedDateRange!.start.toIso8601String().split('T')[0];
    final endDate = _selectedDateRange!.end.toIso8601String().split('T')[0];

    final requestBody = {'startDate': startDate, 'endDate': endDate};

    try {
      final url = AppConfig.backendUrl;
      final response = await http.post(
        Uri.parse('$url/api/v1/report/summary-range'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _reportData = jsonData;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load sales report');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sales report: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.blue.shade600),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchReport();
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingItem(Map<String, dynamic> item, int rank) {
    final maxQuantity = _reportData!['mostSellingItems'][0]['totalQuantity'];
    final progress = item['totalQuantity'] / maxQuantity;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['itemName'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item['totalQuantity']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
          "Sales Report",
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
        actions: [
  IconButton(
    icon: Icon(Icons.picture_as_pdf_rounded, color: Colors.grey.shade800),
    tooltip: 'Download PDF',
    onPressed: _reportData == null
        ? null
        : () => SalesReportPdfGenerator.generateAndShare(_reportData!),
  ),
  IconButton(
    icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade800),
    onPressed: _fetchReport,
    tooltip: 'Refresh',
  ),
],

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header and Date Range Selector
              Text(
                "Sales Analytics",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 24),

              // Date Range Picker
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _showDateRangePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.date_range_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Report Period",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _selectedDateRange == null
                                      ? 'Select Date Range'
                                      : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
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
              ),

              SizedBox(height: 32),

              if (_isLoading)
                Container(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue.shade600,
                    ),
                  ),
                )
              else if (_reportData != null) ...[
                // Stats Cards
                Text(
                  "Key Metrics",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      'Total Sales',
                      '₹${_reportData!['totalSales'].toStringAsFixed(2)}',
                      Icons.trending_up_rounded,
                      Colors.green.shade600,
                    ),
                    _buildStatCard(
                      'Total Orders',
                      '${_reportData!['invoiceCount']}',
                      Icons.receipt_long_rounded,
                      Colors.blue.shade600,
                    ),
                    _buildStatCard(
                      'Average Order',
                      '₹${_reportData!['averageInvoiceValue'].toStringAsFixed(2)}',
                      Icons.analytics_rounded,
                      Colors.orange.shade600,
                    ),
                    _buildStatCard(
                      'Items Sold',
                      '${(_reportData!['mostSellingItems'] as List).fold<int>(0, (sum, item) => sum + (item['totalQuantity'] as num).toInt())}',
                      Icons.shopping_cart_rounded,
                      Colors.purple.shade600,
                    ),
                    // ✅ NEW: Total GST
                    _buildStatCard(
                      'Total GST',
                      '₹${_reportData!['totalGst'].toStringAsFixed(2)}',
                      Icons.account_balance_wallet_rounded,
                      Colors.red.shade600,
                    ),

                    // ✅ NEW: Total Invoice Value
                    _buildStatCard(
                      'Total Invoice Value',
                      '₹${_reportData!['totalInvoiceValue'].toStringAsFixed(2)}',
                      Icons.payments_rounded,
                      Colors.teal.shade600,
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Top Selling Items
                Text(
                  "Items Sold",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 16),

                if ((_reportData!['mostSellingItems'] as List).isNotEmpty)
                  ...(_reportData!['mostSellingItems'] as List)
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildTopSellingItem(item, index + 1);
                      })
                      .toList()
                else
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No sales data for selected period",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else
                Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Select a date range to view report",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
