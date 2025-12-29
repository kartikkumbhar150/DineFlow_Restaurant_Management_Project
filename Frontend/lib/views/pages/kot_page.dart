import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class KotPage extends StatefulWidget {
  const KotPage({super.key});

  @override
  State<KotPage> createState() => _KotPageState();
}

class _KotPageState extends State<KotPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<dynamic> _pendingOrders = [];
  List<dynamic> _completedOrders = [];
  String? _userRole;
  late TabController _tabController;
  StreamSubscription? _streamSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Set<int> _seenOrderIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _getUserRole();
    await _fetchPendingOrders();
    await _fetchCompletedOrders();
    _startOrderStream();
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('notification.mp3'));
    } catch (_) {}
  }

  void _startOrderStream() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final client = http.Client();
      final url = AppConfig.backendUrl;

      final request = http.Request(
        'GET',
        Uri.parse('$url/api/v1/kot/stream'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);

      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.isNotEmpty && line.startsWith('data: ')) {
          try {
            final jsonData = line.substring(6);
            final data = jsonDecode(jsonData);

            if (data is List) {
              _handleNewOrders(data);
            }
          } catch (e) {
            print('Error parsing stream data: $e');
          }
        }
      }, onError: (error) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _startOrderStream();
        });
      }, onDone: () {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _startOrderStream();
        });
      });
    } catch (e) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _startOrderStream();
      });
    }
  }

  void _handleNewOrders(List<dynamic> newOrders) {
    if (!mounted) return;

    bool hasNewOrders = false;

    for (var item in newOrders) {
      if (item['completed'] == false) {
        int orderId = item['orderId'];
        if (!_seenOrderIds.contains(orderId)) {
          _seenOrderIds.add(orderId);
          hasNewOrders = true;
        }
      }
    }

    if (hasNewOrders) {
      _playNotificationSound();
      _fetchPendingOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New order received!'),
            backgroundColor: Colors.blue.shade500,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => _tabController.animateTo(0),
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/kot/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        if (mounted) {
          setState(() {
            _pendingOrders = data
                .where((item) => item['completed'] == false)
                .map((item) => {
              'orderId': item['orderId'],
              'tableNumber': item['tableNumber'],
              'items': [item],
            })
                .toList();

            for (var item in data) {
              if (item['orderId'] != null) {
                _seenOrderIds.add(item['orderId']);
              }
            }

            _pendingOrders.sort((a, b) => b['orderId'].compareTo(a['orderId']));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/kot/completed'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        if (mounted) {
          setState(() {
            _completedOrders = data
                .where((item) => item['completed'] == true)
                .map((item) => {
              'orderId': item['orderId'],
              'tableNumber': item['tableNumber'],
              'items': [item],
            })
                .toList();

            _completedOrders
                .sort((a, b) => b['orderId'].compareTo(a['orderId']));
          });
        }
      }
    } catch (e) {}
  }

  // --- CONFIRMATION DIALOG ---
  Future<void> _showConfirmDialog(dynamic orderId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text('Mark this order as complete?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes, Complete'),
              onPressed: () {
                Navigator.of(context).pop();
                // Safe conversion to int
                int id = int.tryParse(orderId.toString()) ?? 0;
                _markOrderComplete(id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _markOrderComplete(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;

      final res = await http.post(
        Uri.parse('$url/api/v1/kot/mark-complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "orderId": orderId,
        }),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as complete!'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      print("Error marking complete: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchPendingOrders(),
      _fetchCompletedOrders(),
    ]);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kitchen Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingOrders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingOrders.length}',
                        style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
          child: CircularProgressIndicator(color: Colors.blue.shade600))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(_pendingOrders, isPending: true),
          _buildOrderList(_completedOrders, isPending: false),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: const [
            SizedBox(height: 250),
            Center(child: Text('No orders')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(orders[index], isPending: isPending),
      ),
    );
  }





  Widget _buildOrderCard(Map<String, dynamic> order,
      {required bool isPending}) {
    final tableNumber = order['tableNumber'] ?? 'N/A';
    final items = order['items'] as List<dynamic>? ?? [];
    final orderNumber = order['orderId'];
    final isChef = _userRole?.toUpperCase() == 'CHEF';


    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 🔥 VERY IMPORTANT
      onTap: () {
        debugPrint("CARD TAP DETECTED");
        debugPrint("ROLE=$_userRole isChef=$isChef isPending=$isPending");

        if (isPending && isChef) {
          _showConfirmDialog(orderNumber);
        }
      },

      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isPending ? Colors.blue.shade100 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPending
                      ? [Colors.blue.shade500, Colors.blue.shade600]
                      : [Colors.grey.shade600, Colors.grey.shade700],
                ),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant,
                          color: Colors.white),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table $tableNumber',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Order #$orderNumber',
                            style: TextStyle(
                                color: Colors.white.withOpacity(.9),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    isPending ? 'PENDING' : 'COMPLETED',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ITEMS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: items
                    .map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          child: Text('${item['quantity']}'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item['itemName'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ),

            if (isPending && isChef)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
              ),
          ],
        ),
      ),
    );
  }



}