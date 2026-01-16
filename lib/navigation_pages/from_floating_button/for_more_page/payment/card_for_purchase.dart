import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../database/purchase_db.dart';

class CardInHandPurchasePage extends StatefulWidget {
  const CardInHandPurchasePage({Key? key}) : super(key: key);

  @override
  State<CardInHandPurchasePage> createState() => _CardInHandPurchasePageState();
}

class _CardInHandPurchasePageState extends State<CardInHandPurchasePage> {
  double cardBalance = 0.0;
  List<Map<String, dynamic>> cardTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  Future<void> _loadCardData() async {
    final purchases = await PurchaseDB.getAllPurchases();
    List<Map<String, dynamic>> transactions = [];
    double totalCardPurchase = 0.0;

    for (var p in purchases) {
      if ((p['payment_method'] ?? '').toLowerCase() == 'card') {
        transactions.add({
          'type': 'Purchase',
          'name': p['vendor_name'] ?? '',
          'date': p['date'],
          'amount': (p['total_amount'] as num).toDouble(),
          'isCredit': true,
        });
        totalCardPurchase += (p['total_amount'] as num).toDouble();
      }
    }

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
      cardBalance = totalCardPurchase; // FIXED: Removed negative sign
      cardTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Card Used in-purchase',
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
                      "Current Card Balance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹ ${cardBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.credit_card, color: Colors.white, size: 30),
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
                cardTransactions.isEmpty
                    ? const Center(child: Text("No card transactions found."))
                    : ListView.builder(
                      itemCount: cardTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = cardTransactions[index];
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
