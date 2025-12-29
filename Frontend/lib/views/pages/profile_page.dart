import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:projectx/config.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/pages/change_business_details_page.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/views/pages/staff_page.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:projectx/views/pages/privacy_policy.dart';
import 'package:projectx/views/pages/contact_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------- HEADER ----------
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 50),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                          businessLogoNotifier.value,
                        ),
                        radius: 60,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Business Name
                    ValueListenableBuilder<String>(
                      valueListenable: businessNameNotifier,
                      builder: (context, businessName, _) {
                        return Text(
                          businessName.isNotEmpty
                              ? businessName
                              : "Add business details",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // ROLE badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder<String>(
                        valueListenable: roleNotifier,
                        builder: (context, role, _) {
                          if (role.isNotEmpty) {
                            return Text(
                              role,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          } else {
                            return const Text(
                              "Enter Business Details first",
                              style: TextStyle(color: Colors.white),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- BODY ----------
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ValueListenableBuilder<String>(
                      valueListenable: roleNotifier,
                      builder: (context, role, _) {
                        final bool isAdmin = role == "ADMIN";
                        final VoidCallback disabledCallback = () {};

                        return Column(
                          children: [
                            ButtonTile(
                              label: "Add/Remove Staff",
                              onTap: isAdmin
                                  ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const StaffPage(),
                                ),
                              )
                                  : disabledCallback,
                              icon: Icons.people_rounded,
                              bgColor:
                              isAdmin ? Colors.white : Colors.grey.shade300,
                              textColor: isAdmin
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade800.withOpacity(0.4),
                              showShadow: isAdmin,
                            ),

                            const SizedBox(height: 12),

                            ButtonTile(
                              label: "Change Business Details",
                              onTap: isAdmin
                                  ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const ChangeBusinessDetailsPage(),
                                ),
                              )
                                  : disabledCallback,
                              icon: Icons.edit_rounded,
                              bgColor:
                              isAdmin ? Colors.white : Colors.grey.shade300,
                              textColor: isAdmin
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade800.withOpacity(0.4),
                              showShadow: isAdmin,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "Support & Information",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ButtonTile(
                      label: "Privacy Policy",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                      icon: Icons.description_rounded,
                      bgColor: Colors.blue.shade500,
                      textColor: Colors.white,
                    ),

                    const SizedBox(height: 12),

                    ButtonTile(
                      label: "Contact Us",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactPage(),
                          ),
                        );
                      },
                      icon: Icons.phone_rounded,
                      bgColor: Colors.blue.shade500,
                      textColor: Colors.white,
                    ),

                    const SizedBox(height: 32),

                    ButtonTile(
                      label: "Logout",
                      onTap: () => _handleLogout(context),
                      icon: Icons.logout_rounded,
                      bgColor: Colors.red.shade400,
                      textColor: Colors.white,
                    ),

                    const SizedBox(height: 24),
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

/// LOGOUT FUNCTION
void _handleLogout(BuildContext context) async {
  final navigator = Navigator.of(context);
  final prefs = await SharedPreferences.getInstance();

  // Backend logout
  try {
    await http.post(Uri.parse("$url/api/v1/logout"));
  } catch (_) {}

  // CLEAR EVERYTHING RELATED TO PREVIOUS USER
  await prefs.remove('auth_token');
  await prefs.remove('user_name');
  await prefs.remove('role');
  await prefs.remove('business_name');
  await prefs.remove('user_id');

  // Reset UI notifiers (otherwise old admin data stays showing)
  roleNotifier.value = "";
  businessNameNotifier.value = "";
  businessLogoNotifier.value = "";

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
  );
}
