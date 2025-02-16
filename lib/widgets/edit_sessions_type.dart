// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../constants/colors.dart';

/// Reusable EntryVisibility Widget with Show More and Search functionality
class EditSessionsType extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> initialSelectedEntries;

  const EditSessionsType({
    Key? key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.initialSelectedEntries,
  }) : super(key: key);

  @override
  _EditSessionsTypeState createState() => _EditSessionsTypeState();
}

class _EditSessionsTypeState extends State<EditSessionsType> {
  final List<Map<String, dynamic>> entryOptions = [
    {'label': 'Internal sessions', 'value': false},
    {'label': 'External sessions', 'value': false},
    {'label': 'Private sessions', 'value': false},
    // Add more entries as needed
  ];

  List<Map<String, dynamic>> filteredOptions = [];
  TextEditingController searchController = TextEditingController();
  int displayedCount = 3; // Tracks the number of items to display

  @override
  void initState() {
    super.initState();
    // Initialize selected entries based on initialSelectedEntries
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
          return label.contains(searchText);
        }).toList();
      } else {
        filteredOptions = List.from(entryOptions);
      }
      // Reset displayedCount when search text changes
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    // Determine if search is active
    bool isSearching = searchController.text.isNotEmpty;

    // Determine the options to display
    List<Map<String, dynamic>> optionsToDisplay = isSearching
        ? filteredOptions
        : filteredOptions.take(displayedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextHeader("Sessions type"),
        const SizedBox(height: 10),
        // TextField(
        //   controller: searchController,
        //   decoration: InputDecoration(
        //     labelText: getTranslated(context, "Search for an entry"),
        //     prefixIcon: const Icon(Icons.search),
        //     suffixIcon: searchController.text.isNotEmpty
        //         ? IconButton(
        //             icon: const Icon(Icons.clear),
        //             onPressed: _clearSearch,
        //           )
        //         : null,
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(20),
        //     ),
        //     filled: true,
        //     fillColor: Theme.of(context).brightness == Brightness.dark
        //         ? Colors.black
        //         : Colors.white,
        //   ),
        // ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: optionsToDisplay
                .map((option) => _buildCheckboxRow(
                      context,
                      option['label'],
                      option['value'],
                    ))
                .toList(),
          ),
        ),
        // Show "Show more" button if not searching and more options are available
        if (!isSearching && displayedCount < filteredOptions.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showMore,
              child: Text(
                getTranslated(context, "Show more entry types"),
                style: TextStyle(color: kPurpleColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxRow(BuildContext context, String label, bool value) {
    String displayLabel = getTranslated(context, label) != null &&
            getTranslated(context, label)!.isNotEmpty
        ? getTranslated(context, label)!
        : label;
    return Row(
      children: [
        Expanded(
          child: Text(displayLabel),
        ),
        Checkbox(
          checkColor: Colors.white,
          activeColor: kPurpleColor,
          value: value,
          onChanged: (bool? newValue) {
            if (newValue == null) return;
            setState(() {
              optionSetState(label, newValue);
            });
            widget.onCheckboxChanged(newValue, label);
          },
        ),
      ],
    );
  }

  void optionSetState(String label, bool value) {
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

  // Helper method to display headers
  Widget TextHeader(String text) {
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
}
