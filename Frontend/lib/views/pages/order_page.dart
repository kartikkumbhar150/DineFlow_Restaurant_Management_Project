import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/generate_invoice_page.dart';
import 'package:projectx/views/pages/select_item_page.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:projectx/views/widgets/order_list_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/utils/logout.dart';     // <-- use global logout

class OrderPage extends StatefulWidget {
  final int tableNumber;
  final bool isOccupied;

  const OrderPage({
    super.key,
    required this.tableNumber,
    required this.isOccupied,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Map<String, dynamic>> previousOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isOccupied) {
      fetchPreviousOrders();
    } else {
      isLoading = false;
    }
  }

  Future<void> fetchPreviousOrders() async {
    setState(() {
      isLoading = true;
      previousOrders.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = AppConfig.backendUrl;
      final response = await http.get(
        Uri.parse('$url/api/v1/orders/${widget.tableNumber}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data']['items'];

        final List<Map<String, dynamic>> fetchedOrders = [];

        for (var item in data) {
          fetchedOrders.add({
            "name": item['itemName'],
            "quantity": item['quantity'],
            "price": item['price'],
          });
        }

        setState(() {
          previousOrders = fetchedOrders;
          isLoading = false;
        });
      }

      // 🔴 token expired → auto logout
      else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired — logging out")),
        );
        await forceLogout();
      }

      // other errors
      else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Table ${widget.tableNumber} Orders"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            OrderListSection(
              title: "Previous Order",
              items: previousOrders,
            ),
            const SizedBox(height: 20),
            ButtonTile(
              label: "Add More Items",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectItemPage(
                      tableNumber: widget.tableNumber,
                      prevItems: previousOrders.length,
                    ),
                  ),
                );
                fetchPreviousOrders();
              },
              icon: Icons.kitchen,
              bgColor: Colors.blue.shade400,
              textColor: Colors.white,
            ),
            const SizedBox(height: 20),
            ButtonTile(
              label: "Generate Invoice",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenerateInvoicePage(
                      tableNumber: widget.tableNumber,
                    ),
                  ),
                );
              },
              icon: Icons.download,
              bgColor: Colors.green.shade400,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
