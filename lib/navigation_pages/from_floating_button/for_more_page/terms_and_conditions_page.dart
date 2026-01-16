import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
                'Terms & Conditions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'By installing or using this application, you agree to these Terms & Conditions. If you do not agree, do not use the app.',
              ),
              SizedBox(height: 16),
              Text(
                'Your Responsibilities:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('• Ensure accuracy of data you enter'),
              Text('• Maintain compliance with local laws and tax regulations'),
              Text('• Safeguard your device, backups, and exported files'),
              SizedBox(height: 16),
              Text(
                'Data & Backups:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'The app stores data locally. You are responsible for backups.',
              ),
              SizedBox(height: 16),
              Text(
                'Disclaimers:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'The app is provided “as is” without warranties. We do not guarantee that the app will meet every business requirement.',
              ),
              SizedBox(height: 16),
              Text(
                'Governing Law:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('These terms are governed by the laws of India.'),
              SizedBox(height: 16),
              Text(
                'Contact:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'For questions about these terms, contact us via the About page.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
