import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Widget contactCard({
    required String name,
    required String phone,
    required String email,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("Phone: $phone"),
            const SizedBox(height: 4),
            Text("Email: $email"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Us")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            contactCard(
              name: "Person 1",
              phone: "+91XXXXXXXXXX",
              email: "person1@example.com",
            ),
            contactCard(
              name: "Person 2",
              phone: "+91XXXXXXXXXX",
              email: "person2@example.com",
            ),
          ],
        ),
      ),
    );
  }
}
