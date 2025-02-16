import 'package:auto_size_text/auto_size_text.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:flutter/material.dart';

class TypeAccountWidget extends StatelessWidget {
  final String accountType;
  final String selectedTypeAccount;
  final String title;
  final String subtitle;
  final Function(String) onSelected;

  const TypeAccountWidget({
    Key? key,
    required this.accountType,
    required this.selectedTypeAccount,
    required this.title,
    required this.subtitle,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = accountType == selectedTypeAccount;

    return GestureDetector(
      onTap: () {
        onSelected(accountType);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        width: 250, // Set width for each card
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [kPurpleColor, Colors.indigo.shade700]
                      : [kPurpleColor, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? Colors.purple[50]
              : Theme.of(context).brightness == Brightness.dark
                  ? kDarkModeColor
                  : Colors.white,
          border: Border.all(
            color: isSelected
                ? kPurpleColor
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center-align content
          children: [
            // Account Type Icon
            CircleAvatar(
              backgroundColor: isSelected ? kPrimaryColor : Colors.grey,
              radius: 30,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.account_circle,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 15), // Adjusted spacing
            // Account Title
            AutoSizeText(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Account Subtitle
            AutoSizeText(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
