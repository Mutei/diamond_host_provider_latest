// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../constants/colors.dart';

/// Reusable EditMusicServices Widget with Show More and Search functionality
class EditCoffeeMusicServices extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> initialSelectedEntries;

  const EditCoffeeMusicServices({
    Key? key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.initialSelectedEntries,
  }) : super(key: key);

  @override
  _EditCoffeeMusicServicesState createState() =>
      _EditCoffeeMusicServicesState();
}

class _EditCoffeeMusicServicesState extends State<EditCoffeeMusicServices> {
  final List<Map<String, dynamic>> mainOptions = [
    {'label': 'Is there music', 'value': false},
  ];

  final List<Map<String, dynamic>> buffetOptions = [
    {'label': 'singer', 'value': false},
    {'label': 'DJ', 'value': false},
    {'label': "Oud", 'value': false},
    // Add more buffets as needed
  ];

  List<Map<String, dynamic>> filteredMainOptions = [];
  List<Map<String, dynamic>> filteredBuffetOptions = [];
  TextEditingController searchController = TextEditingController();
  int displayedMainCount = 3; // Tracks the number of main items to display
  int displayedBuffetCount = 3; // Tracks the number of buffet items to display

  @override
  void initState() {
    super.initState();
    // Initialize selected main options based on initialSelectedEntries
    for (var option in mainOptions) {
      if (widget.initialSelectedEntries.contains(option['label'])) {
        option['value'] = true;
      }
    }

    // Initialize selected buffets based on initialSelectedEntries
    for (var buffet in buffetOptions) {
      if (widget.initialSelectedEntries.contains(buffet['label'])) {
        buffet['value'] = true;
      }
    }

    // Filter the options initially (handles filtering if needed)
    filteredMainOptions = List.from(mainOptions);
    filteredBuffetOptions = List.from(buffetOptions);

    // Add a listener to the search controller for dynamic filtering
    searchController.addListener(_filterOptions);
  }

  void _filterOptions() {
    setState(() {
      String searchText = searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        filteredMainOptions = mainOptions.where((option) {
          String label = option['label'].toLowerCase();
          return label.contains(searchText);
        }).toList();

        // Also filter buffet options if "Is there music" is selected
        if (_isMusicSelected()) {
          filteredBuffetOptions = buffetOptions.where((buffet) {
            String label = buffet['label'].toLowerCase();
            return label.contains(searchText);
          }).toList();
        } else {
          filteredBuffetOptions = [];
        }
      } else {
        filteredMainOptions = List.from(mainOptions);
        if (_isMusicSelected()) {
          filteredBuffetOptions = List.from(buffetOptions);
        } else {
          filteredBuffetOptions = [];
        }
      }
      // Reset displayed counts when search text changes
      displayedMainCount = 3;
      displayedBuffetCount = 3;
    });
  }

  void _clearSearch() {
    searchController.clear();
  }

  void _showMoreMain() {
    setState(() {
      displayedMainCount += 3;
      if (displayedMainCount > filteredMainOptions.length) {
        displayedMainCount = filteredMainOptions.length;
      }
    });
  }

  void _showMoreBuffet() {
    setState(() {
      displayedBuffetCount += 3;
      if (displayedBuffetCount > filteredBuffetOptions.length) {
        displayedBuffetCount = filteredBuffetOptions.length;
      }
    });
  }

  bool _isMusicSelected() {
    return mainOptions.any((option) =>
        option['label'] == 'Is there music' && option['value'] == true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    // Determine if search is active
    bool isSearching = searchController.text.isNotEmpty;

    // Determine the main options to display
    List<Map<String, dynamic>> optionsToDisplay = isSearching
        ? filteredMainOptions
        : filteredMainOptions.take(displayedMainCount).toList();

    // Determine the buffet options to display
    List<Map<String, dynamic>> buffetOptionsToDisplay = isSearching
        ? filteredBuffetOptions
        : filteredBuffetOptions.take(displayedBuffetCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextHeader("Music"),
        const SizedBox(height: 10),
        // Optional: Uncomment if you want to include a search bar
        /*
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: getTranslated(context, "Search for a music service"),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        */
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: optionsToDisplay
                .map((option) => _buildMainCheckboxRow(
                      context,
                      option['label'],
                      option['value'],
                    ))
                .toList(),
          ),
        ),
        // Show "Show more" button for main options if not searching and more options are available
        if (!isSearching && displayedMainCount < filteredMainOptions.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showMoreMain,
              child: Text(
                getTranslated(context, "Show more music services"),
                style: TextStyle(color: kPurpleColor),
              ),
            ),
          ),
        // Show buffet options if "Is there music" is selected
        if (_isMusicSelected())
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: buffetOptionsToDisplay
                      .map((buffet) => _buildBuffetCheckboxRow(
                            context,
                            buffet['label'],
                            buffet['value'],
                          ))
                      .toList(),
                ),
              ),
              // Show "Show more" button for buffet options if not searching and more options are available
              if (!isSearching &&
                  displayedBuffetCount < filteredBuffetOptions.length)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showMoreBuffet,
                    child: Text(
                      getTranslated(context, "Show more music options"),
                      style: TextStyle(color: kPurpleColor),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainCheckboxRow(BuildContext context, String label, bool value) {
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
              _setMainOptionState(label, newValue);
            });
            widget.onCheckboxChanged(newValue, label);
          },
        ),
      ],
    );
  }

  Widget _buildBuffetCheckboxRow(
      BuildContext context, String label, bool value) {
    String displayLabel = getTranslated(context, label) != null &&
            getTranslated(context, label)!.isNotEmpty
        ? getTranslated(context, label)!
        : label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
                _setBuffetOptionState(label, newValue);
              });
              widget.onCheckboxChanged(newValue, label);
            },
          ),
        ],
      ),
    );
  }

  void _setMainOptionState(String label, bool value) {
    for (var option in mainOptions) {
      if (option['label'] == label) {
        option['value'] = value;
        break;
      }
    }
    // If "Is there music" is unchecked, also uncheck all buffets
    if (label == 'Is there music' && !value) {
      for (var buffet in buffetOptions) {
        if (buffet['value']) {
          buffet['value'] = false;
          widget.onCheckboxChanged(false, buffet['label']);
        }
      }
    }
  }

  void _setBuffetOptionState(String label, bool value) {
    for (var buffet in buffetOptions) {
      if (buffet['label'] == label) {
        buffet['value'] = value;
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
