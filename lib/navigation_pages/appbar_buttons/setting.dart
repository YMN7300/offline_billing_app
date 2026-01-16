import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(title: "Business Settings"),
          SettingsTile(
            title: "Business Profile",
            subtitle: "Edit name, contact, GST etc.",
            onTap: () async {
              final updatedName = await Navigator.pushNamed(
                context,
                "profile_page",
              );
              if (updatedName != null && updatedName is String) {
                Navigator.pop(context, updatedName); // Return the updated name
              }
            },
          ),
          SettingsTile(
            title: "Invoice Settings",
            subtitle: "Customize color",
            onTap: () {
              // Navigate to invoice settings
            },
          ),

          const SizedBox(height: 16),
          const SectionTitle(title: "Inventory & Stock"),
          SettingsTile(
            title: "Stock Settings",
            subtitle: "Enable tracking, alerts, low stock",
            onTap: () {
              // Navigate to stock settings
            },
          ),

          const SizedBox(height: 16),
          const SectionTitle(title: "Date & Time"),
          SettingsTile(
            title: "Date & Time Settings",
            subtitle: "Set financial year, time format",
            onTap: () {
              // Navigate to date and time settings
            },
          ),

          const SizedBox(height: 16),
          const SectionTitle(title: "Appearance"),
          SettingsTile(
            title: "Theme / UI Preferences",
            subtitle: "Dark mode, accent color",
            onTap: () {
              // Navigate to theme settings
            },
          ),
        ],
      ),
    );
  }
}

// 🔹 Reusable section header
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// 🔸 Reusable settings tile
class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
