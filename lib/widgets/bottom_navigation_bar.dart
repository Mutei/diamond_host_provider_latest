import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../state_management/general_provider.dart';
import 'package:badges/badges.dart' as badges;

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? kDarkModeColor
          : Colors.white,
      currentIndex: currentIndex,
      onTap: onItemTapped,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: getTranslated(context, 'Main Screen'),
        ),
        BottomNavigationBarItem(
          icon: Consumer<GeneralProvider>(
            builder: (context, provider, child) {
              if (provider.newRequestCount == 0) {
                return const Icon(
                  Icons.account_box,
                );
              } else {
                return badges.Badge(
                  badgeContent: Text(
                    provider.newRequestCount.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  child: const Icon(
                    Icons.account_box,
                  ),
                );
              }
            },
          ),
          label: getTranslated(context, "Booking Status"),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.post_add),
          label: getTranslated(context, 'All Posts'),
        ),
      ],
    );
  }
}
