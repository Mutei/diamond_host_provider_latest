import 'package:daimond_host_provider/constants/colors.dart';
import 'package:flutter/material.dart';

import '../localization/language_constants.dart';

class AdditionalsRestaurantCoffee extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> selectedAdditionals; // Accept selectedAdditionals

  const AdditionalsRestaurantCoffee({
    super.key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.selectedAdditionals, // Add selectedAdditionals parameter
  });

  @override
  _AdditionalsRestaurantCoffeeState createState() =>
      _AdditionalsRestaurantCoffeeState();
}

class _AdditionalsRestaurantCoffeeState
    extends State<AdditionalsRestaurantCoffee> {
  bool checkHookah = false;
  bool checkBuffet = false;
  bool checkBreakfastBuffet = false;
  bool checkLunchBuffet = false;
  bool checkDinnerBuffet = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    return Column(
      children: [
        _buildCheckboxRow(
          context,
          "Is there Hookah?",
          widget.selectedAdditionals
              .contains("Is there Hookah?"), // Check if it's selected
          (value) {
            widget.onCheckboxChanged(value, "Is there Hookah?");
          },
        ),
        _buildCheckboxRow(
          context,
          "Is there Buffet?",
          widget.selectedAdditionals
              .contains("Is there Buffet?"), // Check if it's selected
          (value) {
            widget.onCheckboxChanged(value, "Is there Buffet?");
            if (!value) {
              checkBreakfastBuffet = false;
              checkLunchBuffet = false;
              checkDinnerBuffet = false;
            }
          },
        ),
        if (checkBuffet)
          Column(
            children: [
              _buildCheckboxRow(
                context,
                "Is there a breakfast buffet?",
                widget.selectedAdditionals.contains(
                    "Is there a breakfast buffet?"), // Check if it's selected
                (value) {
                  widget.onCheckboxChanged(
                      value, "Is there a breakfast buffet?");
                },
              ),
              _buildCheckboxRow(
                context,
                "Is there a lunch buffet?",
                widget.selectedAdditionals.contains(
                    "Is there a lunch buffet?"), // Check if it's selected
                (value) {
                  widget.onCheckboxChanged(value, "Is there a lunch buffet?");
                },
              ),
              _buildCheckboxRow(
                context,
                "Is there a dinner buffet?",
                widget.selectedAdditionals.contains(
                    "Is there a dinner buffet?"), // Check if it's selected
                (value) {
                  widget.onCheckboxChanged(value, "Is there a dinner buffet?");
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCheckboxRow(BuildContext context, String label, bool value,
      Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            getTranslated(context, label),
          ),
        ),
        Expanded(
          child: Checkbox(
            checkColor: Colors.white,
            value: value,
            onChanged: (bool? newValue) => onChanged(newValue!),
            activeColor: kPurpleColor,
          ),
        ),
      ],
    );
  }
}
