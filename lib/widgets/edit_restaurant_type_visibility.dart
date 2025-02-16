import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../localization/language_constants.dart';

class EditRestaurantTypeVisibility extends StatefulWidget {
  final bool isVisible;
  final Function(bool, String) onCheckboxChanged;
  final List<String> initialSelectedTypes;

  const EditRestaurantTypeVisibility({
    Key? key,
    required this.isVisible,
    required this.onCheckboxChanged,
    required this.initialSelectedTypes,
  }) : super(key: key);

  @override
  _EditRestaurantTypeVisibilityState createState() =>
      _EditRestaurantTypeVisibilityState();
}

class _EditRestaurantTypeVisibilityState
    extends State<EditRestaurantTypeVisibility> {
  final List<Map<String, dynamic>> restaurantOptions = [
    {'label': 'Popular restaurant', 'labelAr': 'مطعم شعبي', 'value': false},
    {'label': 'Indian Restaurant', 'labelAr': 'مطعم هندي', 'value': false},
    {'label': 'Italian', 'labelAr': 'إيطالي', 'value': false},
    {
      'label': 'Seafood Restaurant',
      'labelAr': 'مطعم مأكولات بحرية',
      'value': false
    },
    {'label': 'Fast Food', 'labelAr': 'وجبات سريعة', 'value': false},
    {'label': 'Steak', 'labelAr': 'ستيك', 'value': false},
    {'label': 'Grills', 'labelAr': 'مشاوي', 'value': false},
    {'label': 'Healthy', 'labelAr': 'صحي', 'value': false},
    {'label': 'Albanian cuisine', 'labelAr': 'المطبخ الألباني', 'value': false},
    {
      'label': 'Argentinian cuisine',
      'labelAr': 'المطبخ الأرجنتيني',
      'value': false
    },
    {'label': 'American cuisine', 'labelAr': 'المطبخ الأمريكي', 'value': false},
    {
      'label': 'Anglo Indian cuisine',
      'labelAr': 'المطبخ الأنجل-هندي',
      'value': false
    },
    {'label': 'Arabic cuisine', 'labelAr': 'المطبخ العربي', 'value': false},
    {'label': 'Armenian cuisine', 'labelAr': 'المطبخ الأرمني', 'value': false},
    {
      'label': 'Assyrian/Syriac cuisine',
      'labelAr': 'المطبخ الآشوري/السرياني',
      'value': false
    },
    {
      'label': 'Azerbaijani cuisine',
      'labelAr': 'المطبخ الأذربيجاني',
      'value': false
    },
    {
      'label': 'Bangladeshi cuisine',
      'labelAr': 'المطبخ البنغلاديشي',
      'value': false
    },
    {'label': 'Bengali cuisine', 'labelAr': 'المطبخ البنغالي', 'value': false},
    {'label': 'Berber cuisine', 'labelAr': 'المطبخ الأمازيغي', 'value': false},
    {
      'label': 'Brazilian cuisine',
      'labelAr': 'المطبخ البرازيلي',
      'value': false
    },
    {'label': 'British cuisine', 'labelAr': 'المطبخ البريطاني', 'value': false},
    {
      'label': 'Bulgarian cuisine',
      'labelAr': 'المطبخ البلغاري',
      'value': false
    },
    {'label': 'Cajun cuisine', 'labelAr': 'المطبخ الكاجون', 'value': false},
    {
      'label': 'Cantonese cuisine',
      'labelAr': 'المطبخ الكانتوني',
      'value': false
    },
    {
      'label': 'Caribbean cuisine',
      'labelAr': 'المطبخ الكاريبي',
      'value': false
    },
    {'label': 'Chechen cuisine', 'labelAr': 'المطبخ الشيشاني', 'value': false},
    {'label': 'Chinese cuisine', 'labelAr': 'المطبخ صيني', 'value': false},
    {
      'label': 'Chinese Islam cuisine',
      'labelAr': 'المطبخ الصيني الإسلامي',
      'value': false
    },
    {
      'label': 'Circassian cuisine',
      'labelAr': 'المطبخ الشركسي',
      'value': false
    },
    {'label': "Cypriot cuisine", 'labelAr': "المطبخ قبرصي", 'value': false},
    {'label': "Czech cuisine", 'labelAr': "المطبخ التشيكي", 'value': false},
    {'label': "Danish cuisine", 'labelAr': "المطبخ الدنماركي", 'value': false},
    {'label': "Egyptian cuisine", 'labelAr': "المطبخ المصري", 'value': false},
    {'label': "English cuisine", 'labelAr': "المطبخ الإنجليزي", 'value': false},
    {
      'label': "Ethiopian cuisine",
      'labelAr': "المطبخ الإثيوبي",
      'value': false
    },
    {'label': "Eritrean cuisine", 'labelAr': "المطبخ الإريتري", 'value': false},
    {'label': "French cuisine", 'labelAr': "المطبخ الفرنسي", 'value': false},
    {'label': "Filipino cuisine", 'labelAr': "المطبخ الفلبيني", 'value': false},
    {'label': "Georgian cuisine", 'labelAr': "المطبخ الجورجي", 'value': false},
    {'label': "German cuisine", 'labelAr': "المطبخ الألماني", 'value': false},
    {'label': "Greek cuisine", 'labelAr': "المطبخ اليوناني", 'value': false},
    {
      'label': "Hyderabad cuisine",
      'labelAr': "المطبخ الحيدر أباد",
      'value': false
    },
    {'label': "Indian cuisine", 'labelAr': "المطبخ الهندي", 'value': false},
    {
      'label': "Indian Chinese cuisine",
      'labelAr': "المطبخ الهندي الصيني",
      'value': false
    },
    {
      'label': "Indian Singaporean cuisine",
      'labelAr': "المطبخ الهندي السنغافوري",
      'value': false
    },
    {
      'label': "Indonesian cuisine",
      'labelAr': "المطبخ الإندونيسي",
      'value': false
    },
    {'label': "Irish cuisine", 'labelAr': "المطبخ الأيرلندي", 'value': false},
    {
      'label': "Italian-American cuisine",
      'labelAr': "المطبخ الإيطالي الأمريكي",
      'value': false
    },
    {
      'label': "Jamaican cuisine",
      'labelAr': "المطبخ الجامايكي",
      'value': false
    },
    {'label': "Japanese cuisine", 'labelAr': "المطبخ الياباني", 'value': false},
    {
      'label': "Kazakh cuisine",
      'labelAr': "المطبخ الكازاخستاني",
      'value': false
    },
    {'label': "Korean cuisine", 'labelAr': "المطبخ الكوري", 'value': false},
    {'label': "Kurdish cuisine", 'labelAr': "المطبخ الكردي", 'value': false},
    {'label': "Lebanese cuisine", 'labelAr': "المطبخ اللبناني", 'value': false},
    {
      'label': "Malaysian cuisine",
      'labelAr': "المطبخ الماليزي",
      'value': false
    },
    {
      'label': "Malaysian Chinese cuisine",
      'labelAr': "المطبخ الماليزي الصيني",
      'value': false
    },
    {
      'label': "Malaysian Indian cuisine",
      'labelAr': "المطبخ الماليزي الهندي",
      'value': false
    },
    {'label': "Mexican cuisine", 'labelAr': "المطبخ المكسيكي", 'value': false},
    {'label': "Mughal cuisine", 'labelAr': "المطبخ المغولي", 'value': false},
    {
      'label': "Indigenous Cuisine of the Americas",
      'labelAr': "مطبخ السكان الأصليين في الأمريكتين",
      'value': false
    },
    {
      'label': "New Mexico cuisine",
      'labelAr': "مطبخ نيو مكسيكو",
      'value': false
    },
    {'label': "Pashto cuisine", 'labelAr': "المطبخ البشتوني", 'value': false},
    {
      'label': "Pakistani cuisine",
      'labelAr': "المطبخ الباكستاني",
      'value': false
    },
    {'label': "Iranian cuisine", 'labelAr': "المطبخ الإيراني", 'value': false},
    {'label': "Peruvian cuisine", 'labelAr': "المطبخ البيروفي", 'value': false},
    {'label': 'Portuguese cuisine', 'labelAr': 'مطبخ برتغالي', 'value': false},
    {'label': 'Punjabi cuisine', 'labelAr': 'المطبخ البنجابي', 'value': false},
    {'label': 'Serbian cuisine', 'labelAr': 'مطبخ صربي', 'value': false},
    {'label': 'Slovak cuisine', 'labelAr': 'مطبخ سلوفاكي', 'value': false},
    {'label': 'Somali cuisine', 'labelAr': 'مطبخ صومالي', 'value': false},
    {'label': 'Spanish cuisine', 'labelAr': 'مطبخ أسباني', 'value': false},
    {'label': 'Sri Lankan cuisine', 'labelAr': 'مطبخ سريلانكي', 'value': false},
    {'label': 'Taiwanese cuisine', 'labelAr': 'مطبخ تايواني', 'value': false},
    {'label': 'Texas cuisine', 'labelAr': 'مطبخ تكساس', 'value': false},
    {'label': 'Turkish cuisine', 'labelAr': 'مطبخ تركي', 'value': false},
    {'label': 'Ukrainian cuisine', 'labelAr': 'مطبخ أوكراني', 'value': false},
    {'label': 'Vietnamese cuisine', 'labelAr': 'مطبخ فيتنامي', 'value': false},
    {'label': 'Zambian cuisine', 'labelAr': 'مطبخ زامبيا', 'value': false},
    {'label': 'Roman cuisine', 'labelAr': 'مطبخ روماني', 'value': false},
    {'label': 'Romanian cuisine', 'labelAr': 'مطبخ رومانيا', 'value': false},
    {'label': 'Russian cuisine', 'labelAr': 'مطبخ روسي', 'value': false},
    {'label': 'Moroccan cuisine', 'labelAr': 'مطبخ مغربي', 'value': false},
    {'label': 'Tunisian cuisine', 'labelAr': 'مطبخ تونسي', 'value': false},
    {'label': 'Bahraini cuisine', 'labelAr': 'مطبخ بحريني', 'value': false},
    {'label': 'Kuwaiti cuisine', 'labelAr': 'مطبخ كويتي', 'value': false},
    {'label': 'Emirati cuisine', 'labelAr': 'المطبخ الإماراتي', 'value': false},
    {'label': 'Algerian cuisine', 'labelAr': 'مطبخ جزائري', 'value': false},
    {'label': 'Sudanese cuisine', 'labelAr': 'مطبخ سوداني', 'value': false},
    {'label': 'Jordanian cuisine', 'labelAr': 'مطبخ أردني', 'value': false},
    {'label': 'Syrian cuisine', 'labelAr': 'مطبخ سوري', 'value': false},
    {'label': 'Palestinian cuisine', 'labelAr': 'مطبخ فلسطيني', 'value': false},
    {'label': 'Iraqi cuisine', 'labelAr': 'مطبخ عراقي', 'value': false},
  ];

  List<Map<String, dynamic>> filteredOptions = [];
  TextEditingController searchController = TextEditingController();
  int displayedCount = 3; // Tracks the number of items to display

  @override
  void initState() {
    super.initState();
    // Initialize selected options based on initialSelectedTypes
    for (var option in restaurantOptions) {
      if (widget.initialSelectedTypes.contains(option['label'])) {
        option['value'] = true;
      }
    }
    filteredOptions = restaurantOptions;
    searchController.addListener(_filterOptions);
  }

  void _filterOptions() {
    setState(() {
      String searchText = searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        filteredOptions = restaurantOptions.where((option) {
          String labelEn = option['label'].toLowerCase();
          String labelAr = option['labelAr'].toLowerCase();
          return labelEn.contains(searchText) || labelAr.contains(searchText);
        }).toList();
      } else {
        filteredOptions = restaurantOptions;
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
      displayedCount += 5;
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
        TextHedar("Type of Restaurant"),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: getTranslated(context, "Search for a cuisine"),
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
                  ? kDarkModeColor
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: optionsToDisplay
                .map((option) => _buildCheckboxRow(
                      context,
                      option['label'],
                      option['labelAr'],
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
                getTranslated(context, "Show more types of restaurants"),
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxRow(
      BuildContext context, String labelEn, String labelAr, bool value) {
    String displayLabel = getTranslated(context, labelEn) != null &&
            getTranslated(context, labelEn)!.isNotEmpty
        ? getTranslated(context, labelEn)!
        : labelEn;
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
              optionSetState(labelEn, newValue);
            });
            widget.onCheckboxChanged(newValue, labelEn);
          },
        ),
      ],
    );
  }

  void optionSetState(String label, bool value) {
    for (var option in restaurantOptions) {
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
  Widget TextHedar(String text) {
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
