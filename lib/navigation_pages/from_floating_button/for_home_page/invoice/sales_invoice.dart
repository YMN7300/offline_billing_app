import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../database/customer_db.dart';
import '../../../../database/profile_db.dart';

Future<Uint8List> generateSalesInvoicePDF(
  SalesModel sale,
  List<SalesItemModel> items,
) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load(
    'assets/fonts/Poppins/Poppins-Regular.ttf',
  );
  final ttf = pw.Font.ttf(fontData);

  Map<String, dynamic>? customer;
  try {
    customer = await CustomerDB.getCustomerById(sale.id);
    if (customer == null || customer.isEmpty) {
      final allCustomers = await CustomerDB.getAllCustomers();
      customer = allCustomers.firstWhere(
        (c) => c['name'] == sale.customerName,
        orElse: () => {},
      );
    }
  } catch (e) {
    print('Error fetching customer: $e');
  }

  final customerName =
      customer?['name']?.toString().trim() ?? sale.customerName;
  final customerPhone = customer?['phone']?.toString().trim() ?? '';
  final customerGSTIN = customer?['gstin']?.toString().trim() ?? '';
  final customerAddress = customer?['address']?.toString().trim() ?? '';

  final profile = await ProfileDB.getProfile();
  final businessName = profile?.businessName ?? '';
  final businessPhone = profile?.phone ?? '';
  final businessGST = profile?.gst ?? '';
  final businessEmail = profile?.email ?? '';

  double subTotal = items.fold(
    0,
    (sum, item) => sum + (item.rate * item.quantity),
  );
  double totalGst = items.fold(0, (sum, item) => sum + item.taxValue);
  double totalAmount = items.fold(0, (sum, item) => sum + item.totalAmount);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Row: From Info (left) & Title (right)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Business Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'From',
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (businessName.isNotEmpty)
                        pw.Text(
                          'Name: $businessName',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if (businessPhone.isNotEmpty)
                        pw.Text(
                          'Phone: $businessPhone',
                          style: pw.TextStyle(font: ttf, fontSize: 12),
                        ),
                      if (businessGST.isNotEmpty)
                        pw.Text(
                          'GSTIN: $businessGST',
                          style: pw.TextStyle(font: ttf, fontSize: 12),
                        ),
                      if (businessEmail.isNotEmpty)
                        pw.Text(
                          'Email: $businessEmail',
                          style: pw.TextStyle(font: ttf, fontSize: 12),
                        ),
                    ],
                  ),
                  pw.Text(
                    'Sales Invoice',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(height: 1, thickness: 1, color: PdfColors.black),

            // Customer Info + Invoice Info
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To',
                          style: pw.TextStyle(
                            font: ttf,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Name: $customerName',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (customerPhone.isNotEmpty)
                          pw.Text(
                            'Phone: $customerPhone',
                            style: pw.TextStyle(font: ttf, fontSize: 12),
                          ),
                        if (customerGSTIN.isNotEmpty)
                          pw.Text(
                            'GSTIN: $customerGSTIN',
                            style: pw.TextStyle(font: ttf, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice Number: ${sale.salesNo}',
                        style: pw.TextStyle(font: ttf, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${sale.date}',
                        style: pw.TextStyle(font: ttf, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items Table
            pw.Table(
              border: null,
              columnWidths: {
                0: pw.FlexColumnWidth(0.5),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1.5),
                6: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.deepPurple),
                  children: [
                    _buildHeaderCell('#', ttf),
                    _buildHeaderCell('Item Name', ttf),
                    _buildHeaderCell('QTY', ttf),
                    _buildHeaderCell('Unit', ttf),
                    _buildHeaderCell('Price/Unit', ttf),
                    _buildHeaderCell('GST', ttf),
                    _buildHeaderCell('Amount', ttf),
                  ],
                ),
                ...items.asMap().entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      _buildDataCell((entry.key + 1).toString(), ttf),
                      _buildDataCell(entry.value.itemName, ttf, isBold: true),
                      _buildDataCell(entry.value.quantity.toString(), ttf),
                      _buildDataCell(entry.value.unit, ttf),
                      _buildDataCell(
                        '₹ ${entry.value.rate.toStringAsFixed(2)}',
                        ttf,
                      ),
                      _buildDataCell(
                        '₹ ${entry.value.taxValue.toStringAsFixed(2)} (${entry.value.taxPercent.toStringAsFixed(2)}%)',
                        ttf,
                      ),
                      _buildDataCell(
                        '₹ ${entry.value.totalAmount.toStringAsFixed(2)}',
                        ttf,
                      ),
                    ],
                  ),
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.deepPurple400),
                  children: [
                    _buildDataCell(
                      '',
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                    _buildDataCell(
                      'Total',
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                    _buildDataCell(
                      items
                          .fold(0, (sum, item) => sum + item.quantity)
                          .toString(),
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                    _buildDataCell(
                      '',
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                    _buildDataCell(
                      '',
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                    _buildDataCell(
                      '₹ ${totalGst.toStringAsFixed(2)}',
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                    _buildDataCell(
                      '₹ ${totalAmount.toStringAsFixed(2)}',
                      ttf,
                      isBold: true,
                      textColor: PdfColors.white,
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount In Words',
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _amountToWords(totalAmount),
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Terms And Conditions',
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        sale.remarks.isNotEmpty
                            ? sale.remarks
                            : 'Thank you for your business.',
                        style: pw.TextStyle(font: ttf),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildPricingRow(
                          'Sub Total',
                          '₹ ${subTotal.toStringAsFixed(2)}',
                          ttf,
                        ),
                        _buildPricingRow(
                          'GST Amount',
                          '₹ ${totalGst.toStringAsFixed(2)}',
                          ttf,
                        ),
                        pw.SizedBox(height: 8),
                        _buildPricingRow(
                          'Grand Total',
                          '₹ ${totalAmount.toStringAsFixed(2)}',
                          ttf,
                          isBold: true,
                        ),
                        _buildPricingRow('Advance', '₹ 0.00', ttf),
                        _buildPricingRow(
                          'Balance',
                          '₹ ${totalAmount.toStringAsFixed(2)}',
                          ttf,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// === Helper widgets ===
pw.Widget _buildHeaderCell(
  String text,
  pw.Font ttf, {
  PdfColor textColor = PdfColors.white,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 12,
        font: ttf,
        fontWeight: pw.FontWeight.bold,
        color: textColor,
      ),
    ),
  );
}

pw.Widget _buildDataCell(
  String text,
  pw.Font font, {
  bool isBold = false,
  PdfColor textColor = PdfColors.black,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        font: font,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor,
      ),
    ),
  );
}

pw.Widget _buildPricingRow(
  String label,
  String value,
  pw.Font font, {
  bool isBold = false,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          font: font,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          font: font,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    ],
  );
}

// === Amount in Words ===
String _amountToWords(double amount) {
  if (amount == 0) return 'Zero Rupees Only';

  final units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  final tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String convertLessThanOneThousand(int n) {
    if (n == 0) return '';
    if (n < 20) return units[n];
    if (n < 100)
      return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
    return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convertLessThanOneThousand(n % 100)}' : ''}';
  }

  String convert(int n) {
    if (n == 0) return 'Zero';
    List<String> parts = [];

    if (n >= 10000000) {
      parts.add('${convertLessThanOneThousand(n ~/ 10000000)} Crore');
      n %= 10000000;
    }
    if (n >= 100000) {
      parts.add('${convertLessThanOneThousand(n ~/ 100000)} Lakh');
      n %= 100000;
    }
    if (n >= 1000) {
      parts.add('${convertLessThanOneThousand(n ~/ 1000)} Thousand');
      n %= 1000;
    }
    if (n > 0) {
      parts.add(convertLessThanOneThousand(n));
    }
    return parts.join(' ');
  }

  int rupees = amount.floor();
  int paisa = ((amount - rupees) * 100).round();

  String rupeesText = convert(rupees);
  String paisaText = paisa > 0 ? convert(paisa) : '';

  String result =
      rupeesText.isNotEmpty
          ? '$rupeesText Rupees${paisaText.isNotEmpty ? ' and $paisaText Paisa' : ''}'
          : '${paisaText.isNotEmpty ? '$paisaText Paisa' : ''}';

  return '$result only';
}

class SalesModel {
  final int id;
  final String salesNo;
  final String date;
  final String customerName;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String remarks;

  SalesModel({
    required this.id,
    required this.salesNo,
    required this.date,
    required this.customerName,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.remarks,
  });

  factory SalesModel.fromMap(Map<String, dynamic> map) {
    return SalesModel(
      id: map['id'] ?? 0,
      salesNo: map['sales_no'] ?? '',
      date: map['date'] ?? '',
      customerName: map['customer_name'] ?? '',
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      paymentStatus: map['payment_status'] ?? '',
      paymentMethod: map['payment_method'] ?? '',
      remarks: map['remarks'] ?? '',
    );
  }
}

class SalesItemModel {
  final String itemName;
  final String unit;
  final int quantity;
  final double rate;
  final double taxValue;
  final double taxPercent;
  final double discountValue;
  final double totalAmount;

  SalesItemModel({
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.rate,
    required this.taxValue,
    required this.taxPercent,
    required this.discountValue,
    required this.totalAmount,
  });

  factory SalesItemModel.fromMap(Map<String, dynamic> map) {
    double parseTaxPercent(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(numericString) ?? 0.0;
      }
      return 0.0;
    }

    return SalesItemModel(
      itemName: map['item_name'] ?? '',
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      rate: (map['rate'] ?? 0).toDouble(),
      taxValue: (map['tax_value'] ?? 0).toDouble(),
      taxPercent: parseTaxPercent(map['tax_percent']),
      discountValue: (map['discount_value'] ?? 0).toDouble(),
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
    );
  }
}
