import 'package:flutter/material.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/navigation_pages/appbar_buttons/fixed_appbar.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String? expandedSection;

  void toggleSection(String section) {
    setState(() {
      if (expandedSection == section) {
        expandedSection = null;
      } else {
        expandedSection = section;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FixAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: "My Business"),

            // 🔽 SALE SECTION
            ExpandableTile(
              icon: Icons.currency_rupee,
              title: "Sale",
              isExpanded: expandedSection == 'sale',
              onTap: () => toggleSection('sale'),
            ),
            if (expandedSection == 'sale') ...[
              SubItem(
                title: "Sale Reports",
                onTap: () {
                  Navigator.pushNamed(context, "sales_list");
                },
              ),
              SubItem(
                title: "Sale Return (Credit Note) Reports",
                onTap: () {
                  Navigator.pushNamed(context, "sales_return_list");
                },
              ),
            ],

            // 🔽 PURCHASE SECTION
            ExpandableTile(
              icon: Icons.shopping_cart,
              title: "Purchase",
              isExpanded: expandedSection == 'purchase',
              onTap: () => toggleSection('purchase'),
            ),
            if (expandedSection == 'purchase') ...[
              SubItem(
                title: "Purchase Reports",
                onTap: () {
                  Navigator.pushNamed(context, "purchase_list");
                },
              ),
              SubItem(
                title: "Purchase Return (Debit Note) Reports",
                onTap: () {
                  Navigator.pushNamed(context, "purchase_return_list");
                },
              ),
            ],

            // 🔽 REPORT SECTION
            ExpandableTile(
              icon: Icons.bar_chart,
              title: "Item/Stocks Reports",
              isExpanded: expandedSection == 'report',
              onTap: () => toggleSection('report'),
            ),
            if (expandedSection == 'report') ...[
              SubItem(
                title: "Items Summary",
                onTap: () {
                  Navigator.pushNamed(context, "item_summary");
                },
              ),
              SubItem(
                title: "Stock Summary",
                onTap: () {
                  Navigator.pushNamed(context, "stock_summary");
                },
              ),
              // SubItem(
              //   title: "Active & Inactive",
              //   onTap: () {
              //     Navigator.pushNamed(context, "active_inactive_item");
              //   },
              // ),
            ],

            const SizedBox(height: 24),
            SectionTitle(title: "Cash & Bank"),
            CustomListTile(
              icon: Icons.account_balance,
              title: "Bank Accounts",
              onTap: () {
                Navigator.pushNamed(context, "add_bank_account");
              },
            ),
            CustomListTile(
              icon: Icons.wallet,
              title: "Cash In-Hand",
              onTap: () {
                Navigator.pushNamed(context, "cash_in_hand");
              },
            ),

            // 🔽 PAYMENT SECTION
            ExpandableTile(
              icon: Icons.payments_outlined,
              title: "Payment",
              isExpanded: expandedSection == 'payment',
              onTap: () => toggleSection('payment'),
            ),
            if (expandedSection == 'payment') ...[
              PaymentSubItem(
                method: "Cash",
                salesTitle: "from sales (get)",
                purchaseTitle: "for purchase (give)",
                onSalesTap: () {
                  Navigator.pushNamed(context, "cash_from_sales");
                },
                onPurchaseTap: () {
                  Navigator.pushNamed(context, "cash_for_purchase");
                },
              ),
              PaymentSubItem(
                method: "Card",
                salesTitle: "from sales (get)",
                purchaseTitle: "for purchase (give)",
                onSalesTap: () {
                  Navigator.pushNamed(context, "card_from_sales");
                },
                onPurchaseTap: () {
                  Navigator.pushNamed(context, "card_for_purchase");
                },
              ),
              PaymentSubItem(
                method: "UPI",
                salesTitle: "from sales (get)",
                purchaseTitle: "for purchase (give)",
                onSalesTap: () {
                  Navigator.pushNamed(context, "upi_from_sales");
                },
                onPurchaseTap: () {
                  Navigator.pushNamed(context, "upi_for_purchase");
                },
              ),
            ],

            const SizedBox(height: 24),
            SectionTitle(title: "Settings"),
            CustomListTile(
              icon: Icons.settings,
              title: "App Settings",
              onTap: () async {
                final result = await Navigator.pushNamed(context, "setting");
                if (result != null && result is String) {
                  // Update business name in FixedAppBar
                  BusinessNameCache.set(result);
                }
              },
            ),
            // CustomListTile(
            //   icon: Icons.language,
            //   title: "Language",
            //   onTap: () {},
            // ),
            CustomListTile(
              icon: Icons.notifications,
              title: "Notifications",
              onTap: () {
                Navigator.pushNamed(context, "notification");
              },
            ),

            const SizedBox(height: 24),
            SectionTitle(title: "About"),
            CustomListTile(
              icon: Icons.info_outline,
              title: "About Us",
              onTap: () {
                Navigator.pushNamed(context, "about_us");
              },
            ),
            CustomListTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {
                Navigator.pushNamed(context, "privacy_policy");
              },
            ),
            CustomListTile(
              icon: Icons.article_outlined,
              title: "Terms & Conditions",
              onTap: () {
                Navigator.pushNamed(context, "terms_&_condition");
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Expandable tile
class ExpandableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;

  const ExpandableTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      leading: Icon(icon, color: black, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: 24,
        color: black,
      ),
      onTap: onTap,
    );
  }
}

class SubItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SubItem({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(right: 16.0),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: black,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.black,
        ),
        onTap: onTap,
      ),
    );
  }
}

class PaymentSubItem extends StatelessWidget {
  final String method;
  final String salesTitle;
  final String purchaseTitle;
  final VoidCallback onSalesTap;
  final VoidCallback onPurchaseTap;

  const PaymentSubItem({
    super.key,
    required this.method,
    required this.salesTitle,
    required this.purchaseTitle,
    required this.onSalesTap,
    required this.onPurchaseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, bottom: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            method,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 0.0, right: 16.0),
            title: Text(
              salesTitle,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
            onTap: onSalesTap,
          ),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 0.0, right: 16.0),
            title: Text(
              purchaseTitle,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
            onTap: onPurchaseTap,
          ),
        ],
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const CustomListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      leading: Icon(icon, color: black, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: black),
      onTap: onTap,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: black,
        ),
      ),
    );
  }
}
