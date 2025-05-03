import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:madmet/overlays/add_transaction.dart';
import 'package:madmet/pages/home.dart';
import 'package:madmet/pages/profile.dart';
import 'package:madmet/pages/statistics.dart';
import 'package:madmet/pages/wallet.dart';
import '../theme/color.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int pageIndex = 0;
  List<Widget> pages = [
    HomePage(),
    StatisticsPage(),
    WalletsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showAddTransactionOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return AddTransactionOverlay();  // This will be the modal content
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
      bottomNavigationBar: getFooter(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionOverlay(context);
        },
        backgroundColor: primary,
        shape: CircleBorder(),
        child: Icon(
          Icons.add,
          size: 25,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: pageIndex,
      children: pages,
    );
  }

  Widget getFooter() {
    List<IconData> iconItems = [
      Icons.calendar_month,
      Icons.bar_chart,
      Icons.wallet,
      Icons.person,
    ];

    return AnimatedBottomNavigationBar(
      activeColor: primary,
      splashColor: secondary,
      inactiveColor: Colors.black.withOpacity(0.5),
      icons: iconItems,
      activeIndex: pageIndex,
      gapLocation: GapLocation.center,
      notchSmoothness: NotchSmoothness.softEdge,
      leftCornerRadius: 10,
      iconSize: 25,
      rightCornerRadius: 10,
      onTap: (index) {
        selectedTab(index);
      },
    );
  }

  selectedTab(index) {
    setState(() {
      pageIndex = index;
    });
  }
}
