// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../constants/colors.dart';

/// Reusable EntryVisibility Widget with Show More and Search functionality
class EditEntryVisibility extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> initialSelectedEntries;

  const EditEntryVisibility({
    Key? key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.initialSelectedEntries,
  }) : super(key: key);

  @override
  _EditEntryVisibilityState createState() => _EditEntryVisibilityState();
}

class _EditEntryVisibilityState extends State<EditEntryVisibility> {
  // Modified entryOptions with Arabic translations included.
  final List<Map<String, dynamic>> entryOptions = [
    {'label': 'Single', 'labelAr': 'فردي', 'value': false},
    {'label': 'Familial', 'labelAr': 'عائلي', 'value': false},
    {'label': 'mixed', 'labelAr': 'مختلط', 'value': false},
  ];

  List<Map<String, dynamic>> filteredOptions = [];
  TextEditingController searchController = TextEditingController();
  int displayedCount = 3; // Tracks the number of items to display
  bool _isValid = true; // To track validation status

  @override
  void initState() {
    super.initState();
    // Initialize the options with the initial selected entries.
    for (var option in entryOptions) {
      if (widget.initialSelectedEntries.contains(option['label'])) {
        option['value'] = true;
      }
    }
    filteredOptions = List.from(entryOptions);
    searchController.addListener(_filterOptions);
  }

  void _filterOptions() {
    setState(() {
      String searchText = searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        filteredOptions = entryOptions.where((option) {
          String label = option['label'].toLowerCase();
          String labelAr = option['labelAr'].toLowerCase();
          return label.contains(searchText) || labelAr.contains(searchText);
        }).toList();
      } else {
        filteredOptions = List.from(entryOptions);
      }
      displayedCount = 3;
    });
  }

  void _clearSearch() {
    searchController.clear();
  }

  void _showMore() {
    setState(() {
      displayedCount += 3;
      if (displayedCount > filteredOptions.length) {
        displayedCount = filteredOptions.length;
      }
    });
  }

  bool _validateSelection() {
    bool isAnySelected = entryOptions.any((option) => option['value'] == true);
    setState(() {
      _isValid = isAnySelected;
    });
    return isAnySelected;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    bool isSearching = searchController.text.isNotEmpty;
    List<Map<String, dynamic>> optionsToDisplay = isSearching
        ? filteredOptions
        : filteredOptions.take(displayedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textHeader("Entry allowed"),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: optionsToDisplay
                .map((option) => _buildCheckboxRow(context, option))
                .toList(),
          ),
        ),
        if (!_isValid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              getTranslated(context, "You must select at least one session"),
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        if (!isSearching && displayedCount < filteredOptions.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showMore,
              child: Text(
                getTranslated(context, "Show more entry types"),
                style: const TextStyle(color: kPurpleColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxRow(BuildContext context, Map<String, dynamic> option) {
    // Choose the appropriate label based on the locale.
    String displayLabel = Localizations.localeOf(context).languageCode == 'ar'
        ? (option['labelAr'] ?? option['label'])
        : option['label'];

    return Row(
      children: [
        Expanded(child: Text(displayLabel)),
        Checkbox(
          checkColor: Colors.white,
          activeColor: kPurpleColor,
          value: option['value'],
          onChanged: (bool? newValue) {
            if (newValue == null) return;
            setState(() {
              _setOptionValue(option['label'], newValue);
            });
            widget.onCheckboxChanged(newValue, option['label']);
            _validateSelection();
          },
        ),
      ],
    );
  }

  void _setOptionValue(String label, bool value) {
    for (var option in entryOptions) {
      if (option['label'] == label) {
        option['value'] = value;
        break;
      }
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_filterOptions);
    searchController.dispose();
    super.dispose();
  }

  Widget _textHeader(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 10),
      child: Text(
        getTranslated(context, text),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Public method to validate selection externally
  bool validateSelection() {
    return _validateSelection();
  }
}
