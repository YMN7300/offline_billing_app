import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../database/sales_db.dart';

class SalesCashPage extends StatefulWidget {
  const SalesCashPage({Key? key}) : super(key: key);

  @override
  State<SalesCashPage> createState() => _SalesCashPageState();
}

class _SalesCashPageState extends State<SalesCashPage> {
  double cashBalance = 0.0;
  List<Map<String, dynamic>> cashTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadCashData();
  }

  Future<void> _loadCashData() async {
    final sales = await SalesDB.getAllSales();

    List<Map<String, dynamic>> transactions = [];
    double totalSalesCash = 0.0;

    for (var s in sales) {
      if ((s['payment_method'] ?? '').toLowerCase() == 'cash') {
        transactions.add({
          'type': 'Sale',
          'name': s['customer_name'] ?? '',
          'date': s['date'],
          'amount': (s['total_amount'] as num).toDouble(),
        });
        totalSalesCash += (s['total_amount'] as num).toDouble();
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
      cashBalance = totalSalesCash;
      cashTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Cash',
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
                      "Total Sales Cash",
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
                  color: Colors.white,
                  size: 30,
                ),
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
                cashTransactions.isEmpty
                    ? const Center(child: Text("No cash sales found."))
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
                          formattedDate = tx['date'];
                        }

                        return ListTile(
                          title: Text("${tx['type']} - ${tx['name']}"),
                          subtitle: Text(formattedDate),
                          trailing: Text(
                            "₹ ${tx['amount'].toStringAsFixed(2)}",
                            style: const TextStyle(
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
