import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey.shade50,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        title: Text(
          "Privacy Policy",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Privacy Policy",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Last updated: 29 December 2025",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "This Privacy Policy explains how our application service DineFlow "
                      "collects, uses, stores, and protects "
                      "personal information when you use our Restaurant management system "
                      "(DineFlow).\n\n"
                      "By using the Service, you agree to this Policy.\n\n"
                      "We comply with applicable Indian laws, including the Digital Personal "
                      "Data Protection Act, 2023 (DPDP Act) and the Information Technology Act & Rules.",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                ),

                const SizedBox(height: 20),

                _sectionTitle("1. Information We Collect"),
                _bulletTitle("a) Information you provide"),
                _bullets([
                  "Name, phone number, email",
                  "Restaurant details (name, address, GST/tax info)",
                  "User accounts (username/password — stored securely)",
                  "Orders, invoices, and billing data",
                  "Support requests and communications",
                ]),
                _bulletTitle("b) Automatically collected information"),
                _bullets([
                  "Device type, browser, operating system",
                  "IP address and approximate location",
                  "Usage logs and activity histories",
                  "Cookies and similar technologies",
                ]),
                _bulletTitle("c) Third-party information"),
                _paragraph(
                    "If you integrate payment gateways, POS, or delivery partners, "
                        "we may receive related data from them as allowed by their policies.\n\n"
                        "We do not collect more than what is necessary for providing the Service."
                ),

                _sectionTitle("2. Purpose of Processing"),
                _bullets([
                  "Run and improve the Service",
                  "Manage menus, inventory, orders, billing, and reports",
                  "Authenticate users and manage access",
                  "Provide customer support and service updates",
                  "Prevent fraud and ensure security",
                  "Meet legal and regulatory requirements",
                  "Analyze performance and enhance features",
                ]),
                _paragraph("We do not sell personal information."),

                _sectionTitle("3. Lawful Basis & Consent (India)"),
                _paragraph(
                    "Where required, we obtain your consent before processing personal data. "
                        "You may withdraw consent at any time — however, some features may stop working.\n\n"
                        "We also process data where necessary for providing the Service, "
                        "security/fraud prevention, legal obligations, and dispute resolution."
                ),

                _sectionTitle("4. Sharing of Information"),
                _bullets([
                  "Service providers (hosting, analytics, payments, SMS/email delivery)",
                  "Partners or integrations you choose to connect",
                  "Government/authorities where legally required",
                  "Business successors during merger or acquisition (with notice)",
                ]),
                _paragraph(
                    "All third parties are bound by confidentiality and data-protection obligations."
                ),

                _sectionTitle("5. Data Storage & Security"),
                _paragraph(
                    "We use safeguards such as encryption, secure servers, access controls, "
                        "and monitoring. If a breach occurs, we will notify affected users as required by law."
                ),

                _sectionTitle("6. Data Retention"),
                _paragraph(
                    "We retain data only as long as needed for the Service, legal/tax compliance, "
                        "and dispute resolution. You may request deletion (see Section 9)."
                ),

                _sectionTitle("7. Cookies"),
                _paragraph(
                    "We use cookies to keep you logged in, remember preferences, and analyze usage. "
                        "You can disable cookies, but some features may not work."
                ),

                _sectionTitle("8. Children’s Privacy"),
                _paragraph(
                    "The Service is not intended for children under 18. We do not knowingly collect data from minors."
                ),

                _sectionTitle("9. Your Rights (Under Indian Law)"),
                _bullets([
                  "Access your data",
                  "Request corrections",
                  "Withdraw consent",
                  "Request deletion (subject to legal limits)",
                  "Lodge a grievance",
                ]),
                _paragraph(
                    "Contact our Grievance Officer to make a request. We will respond within reasonable timelines."
                ),

                _sectionTitle("10. International Transfers"),
                _paragraph(
                    "If data is transferred outside India, we ensure safeguards consistent with Indian law."
                ),

                _sectionTitle("11. Third-Party Links"),
                _paragraph(
                    "We are not responsible for the privacy practices of third-party websites or services."
                ),

                _sectionTitle("12. Updates to This Policy"),
                _paragraph(
                    "We may update this Policy occasionally. Continued use means you accept the revised Policy."
                ),

                _sectionTitle("13. Contact & Grievance Officer"),
                _paragraph(
                    "Grievance Officer: [Name]\n"
                        "Email: [support@example.com]\n"
                        "Address: [Business Address]\n"
                        "Phone (optional): [Contact Number]"
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    ),
  );

  Widget _paragraph(String text) => Text(
    text,
    style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.45),
  );

  Widget _bulletTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    ),
  );

  Widget _bullets(List<String> items) => Column(
    children: items
        .map(
          (e) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                e,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
              ),
            ),
          )
        ],
      ),
    )
        .toList(),
  );
}
