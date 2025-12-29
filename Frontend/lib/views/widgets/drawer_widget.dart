import 'package:flutter/material.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/pages/expense_report_page.dart';
import 'package:projectx/views/pages/kot_page.dart';
import 'package:projectx/views/pages/most_selling_items_page.dart';
import 'package:projectx/views/pages/sales_report_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/config.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                  Colors.indigo.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        // Profile Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<String?>(
                            valueListenable: businessLogoNotifier,
                            builder: (context, logoUrl, _) {
                              final imageProvider =
                                  (logoUrl != null && logoUrl.isNotEmpty)
                                  ? NetworkImage(logoUrl)
                                  : const NetworkImage(
                                      "https://res.cloudinary.com/da2iczspm/image/upload/v1756783467/Black_and_White_Icon_Illustrative_Catering_Logo_rgsdwr.png",
                                    );

                              return CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                backgroundImage: imageProvider,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        ValueListenableBuilder(
                          valueListenable: businessNameNotifier,
                          builder: (context, businessName, child) {
                            return Text(
                              businessName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 6),

                        // Email
                        ValueListenableBuilder(
                          valueListenable: userPhoneNotifier,
                          builder: (context, phone, child) {
                            return Text(
                              "+91 $phone",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 4),

                        // ROLE BADGE
                        ValueListenableBuilder<String>(
                          valueListenable: roleNotifier,
                          builder: (context, role, _) {
                            // Choose badge color based on role
                            Color badgeColor = Colors.orange.shade400;

                            if (role == "ADMIN")
                              badgeColor = Colors.green.shade500;
                            if (role == "CHEF")
                              badgeColor = Colors.blue.shade500;
                            if (role == "STAFF")
                              badgeColor = Colors.purple.shade500;

                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                role.isEmpty ? "Unknown Role" : role,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: roleNotifier,
              builder: (context, role, _) {
                final bool isAdmin = role == "ADMIN";

                // No-op function for disabled items
                final VoidCallback disabledTap = () {};

                return ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSectionHeader("Reports & Analytics"),

                    // ---------------- Most Selling Items ----------------
                    _buildMenuItem(
                      icon: Icons.graphic_eq,
                      title: "Most Selling Items",
                      onTap: isAdmin
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MostSellingItemsPage(),
                                ),
                              );
                            }
                          : disabledTap,
                      textColor: isAdmin
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                    ),

                    // ---------------- Sales Report ----------------
                    _buildMenuItem(
                      icon: Icons.trending_up_rounded,
                      title: "Sales Report",
                      onTap: isAdmin
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalesReportPage(),
                                ),
                              );
                            }
                          : disabledTap,
                      textColor: isAdmin
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                    ),

                    // ---------------- Expense Report ---------------
                    _buildMenuItem(
                      icon: Icons.trending_up_rounded,
                      title: "Expense Report",
                      onTap: isAdmin
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpenseReportPage(),
                          ),
                        );
                      }
                          : disabledTap,
                      textColor: isAdmin
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                    ),

                    // ---------------- KOT  ----------------
                    _buildMenuItem(
                      icon: Icons.kitchen,
                      title: "KOT",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => KotPage()),
                        );
                      },
                    ),

                    Divider(height: 32),

                    _buildSectionHeader("Management"),

                    _buildMenuItem(
                      icon: Icons.settings_rounded,
                      title: "Settings",
                      onTap: () {
                        selectedPageNotifier.value = 3;
                        Navigator.of(context).pop();
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.help_rounded,
                      title: "Help & Support",
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: "Logout",
                      textColor: Colors.red.shade600,
                      onTap: () {
                        _handleLogout(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    navigator.pop(); // close drawer
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? Colors.blue.shade600).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor ?? Colors.blue.shade600, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildExpandableMenuItem({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade600.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade600, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      iconColor: Colors.blue.shade600,
      collapsedIconColor: Colors.grey.shade600,
      tilePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      childrenPadding: EdgeInsets.only(left: 16),
      children: children,
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.grey.shade600, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      dense: true,
    );
  }
}
