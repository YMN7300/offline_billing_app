import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../database/purchase_db.dart';
import '../../../database/sales_db.dart';

class CashInHandPage extends StatefulWidget {
  const CashInHandPage({Key? key}) : super(key: key);

  @override
  State<CashInHandPage> createState() => _CashInHandPageState();
}

class _CashInHandPageState extends State<CashInHandPage> {
  double cashBalance = 0.0;
  List<Map<String, dynamic>> cashTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadCashData();
  }

  Future<void> _loadCashData() async {
    final sales = await SalesDB.getAllSales();
    final purchases = await PurchaseDB.getAllPurchases();

    List<Map<String, dynamic>> transactions = [];
    double totalSalesCash = 0.0;
    double totalPurchaseCash = 0.0;

    // Process Sales
    for (var s in sales) {
      if ((s['payment_method'] ?? '').toLowerCase() == 'cash') {
        transactions.add({
          'type': 'Sale',
          'name': s['customer_name'] ?? '',
          'date': s['date'],
          'amount': (s['total_amount'] as num).toDouble(),
          'isCredit': false,
        });
        totalSalesCash += (s['total_amount'] as num).toDouble();
      }
    }

    // Process Purchases
    for (var p in purchases) {
      if ((p['payment_method'] ?? '').toLowerCase() == 'cash') {
        transactions.add({
          'type': 'Purchase',
          'name': p['vendor_name'] ?? '',
          'date': p['date'],
          'amount': (p['total_amount'] as num).toDouble(),
          'isCredit': true,
        });
        totalPurchaseCash += (p['total_amount'] as num).toDouble();
      }
    }

    // Sort by date (latest first)
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
      cashBalance = totalSalesCash - totalPurchaseCash;
      cashTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cash in-Hand',
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
          // Cash Balance Card
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
                      "Current Cash Balance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹ ${cashBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
          ),

          // Transaction Title
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

          // Transaction List
          Expanded(
            child:
                cashTransactions.isEmpty
                    ? const Center(child: Text("No cash transactions found."))
                    : ListView.builder(
                      itemCount: cashTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = cashTransactions[index];
                        String formattedDate;
                        try {
                          formattedDate = DateFormat(
                            'dd MMM yyyy',
                          ).format(DateFormat('dd-MM-yyyy').parse(tx['date']));
                        } catch (e) {
                          formattedDate =
                              tx['date']; // fallback if parsing fails
                        }

                        return ListTile(
                          title: Text("${tx['type']} - ${tx['name']}"),
                          subtitle: Text(formattedDate),
                          trailing: Text(
                            "₹ ${tx['amount'].toStringAsFixed(2)}",
                            style: TextStyle(
                              color: tx['isCredit'] ? Colors.red : Colors.green,
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
