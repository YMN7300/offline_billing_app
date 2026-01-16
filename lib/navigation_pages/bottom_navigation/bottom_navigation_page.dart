import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'home_page.dart';
import 'items_page.dart';
import 'more_page.dart';

class BottomNavigationPage extends StatefulWidget {
  final int initialIndex;

  const BottomNavigationPage({super.key, this.initialIndex = 0});

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigationPage> {
  late int mycurrentIndex;

  // List of pages
  final List<Widget> pages = [
    HomePage(),
    DashboardPage(),
    ItemsPage(),
    MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    mycurrentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (mycurrentIndex != 0) {
          // If not on Home tab → go to Home tab
          setState(() {
            mycurrentIndex = 0;
          });
          return false; // prevent app from closing
        }
        return true; // allow app to close when already on Home
      },
      child: Scaffold(
        body: pages[mycurrentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: mycurrentIndex,
          onTap: (index) {
            setState(() {
              mycurrentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: "Items",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
          ],
        ),
      ),
    );
  }
}
