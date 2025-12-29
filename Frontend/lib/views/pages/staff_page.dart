import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/add_staff_page.dart';
import 'dart:convert';

import 'package:projectx/views/widgets/button_tile.dart';
import 'package:projectx/views/widgets/single_staff.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectx/views/pages/login_page.dart';   // 👈 ADD THIS

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  List<dynamic> staffList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  // 🔴 AUTO LOGOUT (401 par)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!mounted) return;

    // thoda wait so snackbar visible rahe
    await Future.delayed(const Duration(milliseconds: 700));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _fetchStaff() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/staff'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        staffList = (json['data'] ?? []) as List;
      } else if (res.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired — logging out")),
        );
        _logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load staff: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading staff: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _revokeStaff(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.delete(
        Uri.parse('$url/api/v1/staff/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Staff revoked successfully")),
        );
        _fetchStaff();
      } else if (res.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired — logging out")),
        );
        _logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to revoke staff: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error revoking staff: $e")),
      );
    }
  }

  void _confirmRevoke(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Revoke Staff"),
        content: Text("Are you sure you want to revoke $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _revokeStaff(id);
            },
            child: const Text(
              "Revoke",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddStaffPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddStaffPage()),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Staff added")),
      );
      _fetchStaff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Page')),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _fetchStaff,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 30, 15, 20),
              child: Column(
                children: [
                  ButtonTile(
                    label: "Add Staff",
                    onTap: _openAddStaffPage,
                    icon: Icons.add_rounded,
                    bgColor: Colors.blue.shade500,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 18),
                  if (staffList.isEmpty)
                    const Text("No staff members found"),
                  ...staffList.map((staff) {
                    final int id = staff['id'];
                    final String name = staff['name'] ?? '';
                    final String role = staff['role'] ?? '';
                    final String phone = staff['userName'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SingleStaff(
                        id: id,
                        phone: phone,
                        role: role,
                        staffName: name,
                        onTap: () => _confirmRevoke(id, name),
                      ),
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
