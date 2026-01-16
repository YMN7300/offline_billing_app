import 'package:flutter/material.dart';
import 'package:offline_billing/database/product_db.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final products = await ProductDB.getAllProducts();
    final lowStockItems =
        products.where((p) {
          final stock = p['stockQuantity'] ?? 0;
          final alert = p['lowStockAlert'] ?? 0;
          return alert > 0 && stock <= alert;
        }).toList();

    setState(() {
      _notifications = lowStockItems;
      _isLoading = false;
    });
  }

  Widget _buildNotificationTile(Map<String, dynamic> product) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      ),
      title: Text(
        product['name'] ?? 'Unnamed Product',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "Stock: ${product['stockQuantity']} (Alert: ${product['lowStockAlert']})",
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {
        // Optional: Navigate to product details or edit page
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(
                child: Text(
                  "No Notifications",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildNotificationTile(_notifications[index]);
                },
              ),
    );
  }
}
