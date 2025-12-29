import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/bulk_add_item_page.dart';
import 'package:projectx/views/pages/excel_add_item_page.dart';
import 'dart:convert';

import 'package:projectx/views/widgets/button_tile.dart';
import 'package:projectx/views/widgets/single_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_item_page.dart';
import 'package:projectx/utils/logout.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  List<Map<String, dynamic>> groupedItems = [];
  bool isLoading = true;
  bool isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadCachedItems();
    _fetchItems();
  }

  void _openItemOptions(Map<String, dynamic> item) {
    TextEditingController nameCtrl = TextEditingController(text: item['name']);
    TextEditingController priceCtrl = TextEditingController(
      text: item['price'].toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
                "Edit Item",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateItem(
                      item['id'],
                      nameCtrl.text,
                      double.tryParse(priceCtrl.text) ?? item['price'],
                    );
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ),

              SizedBox(height: 12),

              // DELETE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _deleteItem(item['id']);
                  },
                  child: Text("Delete", style: TextStyle(color: Colors.white)),
                ),
              ),

              SizedBox(height: 12),

              // CANCEL
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateItem(int id, String name, double price) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final url = AppConfig.backendUrl;
    final res = await http.put(
      Uri.parse('$url/api/v1/products/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"name": name, "price": price}),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item updated")));
      _fetchItems();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update item")));
    }
  }

  Future<void> _deleteItem(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final url = AppConfig.backendUrl;
    final res = await http.delete(
      Uri.parse('$url/api/v1/products/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item deleted")));
      _fetchItems();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete item")));
    }
  }

  /// Load cached items instantly
  Future<void> _loadCachedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_products');
    if (cached != null) {
      try {
        final List<dynamic> data = jsonDecode(cached);
        _groupItemsByCategory(data);
        setState(() => isLoading = false);
      } catch (e) {
        debugPrint("Failed to decode cached products: $e");
      }
    }
  }

  /// Fetch fresh items from API
  Future<void> _fetchItems() async {
    setState(() {
      isFetching = true;
      if (groupedItems.isEmpty) isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final json = jsonDecode(res.body);

      if (json['status'] == 'success') {
        final List<dynamic> data = json['data'];
        _groupItemsByCategory(data);
        await prefs.setString('cached_products', jsonEncode(data)); // cache it
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load items: ${res.statusCode}"),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading items: $e"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isFetching = false;
      });
    }
  }

  void _groupItemsByCategory(List<dynamic> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in items) {
      final category = item['category'] ?? 'Uncategorized';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(Map<String, dynamic>.from(item));
    }

    setState(() {
      groupedItems = grouped.entries.map((e) {
        return {'category': e.key, 'items': e.value};
      }).toList();
    });
  }

  void _openAddItemPage() async {
    final categories = groupedItems
        .map((item) => item['category'] as String)
        .toSet()
        .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddItemPage(categories: categories)),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Item added"),
          backgroundColor: Colors.blue.shade500,
        ),
      );
      _fetchItems(); // refresh after add
    }
  }

  void _openBulkAddItemPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BulkAddItemPage()),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Items added"),
          backgroundColor: Colors.blue.shade500,
        ),
      );
      _fetchItems(); // refresh after add
    }
  }

  void _openExcelAddItemPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExcelBulkUploadPage()),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Items added"),
          backgroundColor: Colors.blue.shade500,
        ),
      );
      _fetchItems(); // refresh after add
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue.shade600),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchItems,
          color: Colors.blue.shade600,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Items",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ButtonTile(
                    label: "Add Item",
                    onTap: _openAddItemPage,
                    icon: Icons.add_rounded,
                    bgColor: Colors.blue.shade500,
                    textColor: Colors.white,
                  ),
                  SizedBox(height: 8),
                  ButtonTile(
                    label: "Bulk Add Items",
                    onTap: _openBulkAddItemPage,
                    icon: Icons.camera_alt_rounded,
                    bgColor: Colors.blue.shade500,
                    textColor: Colors.white,
                  ),
                  SizedBox(height: 8),
                  ButtonTile(
                    label: "Add Items using Excel",
                    onTap: _openExcelAddItemPage,
                    icon: Icons.description_rounded,
                    bgColor: Colors.blue.shade500,
                    textColor: Colors.white,
                  ),
                  if (isFetching) ...[
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  if (groupedItems.isEmpty)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No items found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add your first item to get started",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...groupedItems.map((cat) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade500,
                                Colors.blue.shade600,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade500.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            cat["category"],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        ...List.generate(
                          cat["items"].length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SingleItem(
                              itemName: cat["items"][i]["name"],
                              price: cat["items"][i]["price"],
                              onTap: () {
                                _openItemOptions(cat["items"][i]);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
