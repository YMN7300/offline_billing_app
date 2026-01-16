import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  final String businessName;

  const AboutUsPage({super.key, this.businessName = 'Your Business Name'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About US',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About Us',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'We build an offline billing and inventory application designed for small businesses that need fast, reliable, and privacy-friendly billing. The app works completely offline—no internet required—so your sales, purchases, items, vendors, and customers stay on your device.',
              ),
              const SizedBox(height: 16),
              const Text(
                'What the App Does:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Create and manage Sales & Purchase entries'),
              const Text('• Maintain Items/Products with stock tracking'),
              const Text('• Handle Vendors, Customers, Returns, and Payments'),
              const Text('• Generate clean invoices as printable PDFs'),
              const Text('• Dashboard insights and basic reports'),
              const SizedBox(height: 16),
              const Text(
                'Why Offline?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Offline-first means speed, control, and peace of mind. Your data belongs to you and lives locally on your device.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'For support or feedback, contact us at your email/phone.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
