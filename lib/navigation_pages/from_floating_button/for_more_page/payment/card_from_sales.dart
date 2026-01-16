import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../database/sales_db.dart';

class CardInHandSalesPage extends StatefulWidget {
  const CardInHandSalesPage({Key? key}) : super(key: key);

  @override
  State<CardInHandSalesPage> createState() => _CardInHandSalesPageState();
}

class _CardInHandSalesPageState extends State<CardInHandSalesPage> {
  double cardBalance = 0.0;
  List<Map<String, dynamic>> cardTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  Future<void> _loadCardData() async {
    final sales = await SalesDB.getAllSales();
    List<Map<String, dynamic>> transactions = [];
    double totalCardSales = 0.0;

    for (var s in sales) {
      if ((s['payment_method'] ?? '').toLowerCase() == 'card') {
        transactions.add({
          'type': 'Sale',
          'name': s['customer_name'] ?? '',
          'date': s['date'],
          'amount': (s['total_amount'] as num).toDouble(),
          'isCredit': false,
        });
        totalCardSales += (s['total_amount'] as num).toDouble();
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
      cardBalance = totalCardSales;
      cardTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Card Used in-sales',
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
              color: Colors.green,
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
                            style: TextStyle(
                              color: Colors.green,
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
