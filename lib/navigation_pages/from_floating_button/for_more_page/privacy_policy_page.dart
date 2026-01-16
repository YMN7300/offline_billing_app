import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
            children: const [
              Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'This Privacy Policy explains how the app collects, uses, and protects information. This is an offline billing application: your operational data (sales, purchases, items, vendors, customers, returns, profile, settings) is stored locally on your device.',
              ),
              SizedBox(height: 16),
              Text(
                'Data We Store:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('• Business profile information you enter'),
              Text(
                '• Operational records (sales, purchases, items, stock, vendors, customers, returns)',
              ),
              Text('• Invoice templates and settings'),
              SizedBox(height: 16),
              Text(
                'How Data Is Stored:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Data is saved locally using an on-device database. We do not transmit your data to servers.',
              ),
              SizedBox(height: 16),
              Text(
                'Permissions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('• Storage: to save and export PDFs'),
              Text('• Camera/Photos: for logo or image attachments'),
              SizedBox(height: 16),
              Text(
                'Security:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'We rely on your device security. Protect your device and backups.',
              ),
              SizedBox(height: 16),
              Text(
                'Contact:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'For privacy questions, contact us via the About page details.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
