import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../database/purchase_db.dart';

class UPIPurchasePage extends StatefulWidget {
  const UPIPurchasePage({Key? key}) : super(key: key);

  @override
  State<UPIPurchasePage> createState() => _UPIPurchasePageState();
}

class _UPIPurchasePageState extends State<UPIPurchasePage> {
  double upiBalance = 0.0;
  List<Map<String, dynamic>> upiTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadUPIData();
  }

  Future<void> _loadUPIData() async {
    final purchases = await PurchaseDB.getAllPurchases();

    List<Map<String, dynamic>> transactions = [];
    double totalPurchaseUPI = 0.0;

    for (var p in purchases) {
      if ((p['payment_method'] ?? '').toLowerCase() == 'upi') {
        transactions.add({
          'type': 'Purchase',
          'name': p['vendor_name'] ?? '',
          'date': p['date'],
          'amount': (p['total_amount'] as num).toDouble(),
        });
        totalPurchaseUPI += (p['total_amount'] as num).toDouble();
      }
    }

    // Sort by date
    transactions.sort((a, b) {
      try {
        DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['date']);
        DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['date']);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      upiBalance = totalPurchaseUPI;
      upiTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UPI puchase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total UPI Purchases",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹ ${upiBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.qr_code, color: Colors.white, size: 30),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transaction Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child:
                upiTransactions.isEmpty
                    ? const Center(
                      child: Text("No UPI purchase transactions found."),
                    )
                    : ListView.builder(
                      itemCount: upiTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = upiTransactions[index];
                        String formattedDate;
                        try {
                          formattedDate = DateFormat(
                            'dd MMM yyyy',
                          ).format(DateFormat('dd-MM-yyyy').parse(tx['date']));
                        } catch (e) {
                          formattedDate = tx['date'];
                        }
                        return ListTile(
                          title: Text("${tx['type']} - ${tx['name']}"),
                          subtitle: Text(formattedDate),
                          trailing: Text(
                            "₹ ${tx['amount'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
