// lib/widgets/riyadh_metro_picker.dart
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../constants/colors.dart';
import '../widgets/reused_provider_estate_container.dart';

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

/// EN canonical list of Riyadh Metro stations by line (as saved to DB).
final Map<String, List<String>> riyadhMetroStationsEn = {
  'Blue': [
    'SAB Bank',
    'DR SULAIMAN AL HABIB',
    'KAFD',
    'Al Murooj',
    'King Fahd District',
    'King Fahd District 2',
    'STC',
    'Al Wurud 2',
    'Al Urubah',
    'Alinma Bank',
    'Bank Albilad',
    'King Fahd Library',
    'Ministry of Interior',
    'Al Muorabba',
    'Passport Department',
    'National Museum',
    'Al Batha',
    'Qasr Al Hokm',
    'Al Owd',
    'Skirinah',
    'Manfouhah',
    'Al Iman Hospital',
    'Transportation Center',
    'Al Aziziah',
    'Ad Dar Al Baida',
  ],
  'Red': [
    'King Saud University',
    'King Salman Oasis',
    'KACST',
    'At Takhassussi',
    'STC',
    'Al Wurud',
    'King Abdulaziz Road',
    'Ministry of Education',
    'An Nuzhah',
    'Riyadh Exhibition Center',
    'Khalid Bin Alwaleed Road',
    'Al Hamra',
    'Al khaleej',
    'Ishbiliyah',
    'King Fahd Sport City',
  ],
  'Orange': [
    'Jeddah Road',
    'Tuwaiq',
    'Ad Douh',
    'Aishah bint Abi Bakr Street',
    'Dhahrat Al Badiah',
    'Sultanah',
    'Al Jarradiyah',
    'Courts Complex',
    'Qasr Al Hokm',
    'Al Hilla',
    'Al Margab',
    'As Salhiyah',
    'First Industrial City',
    'Railway',
    'Al Malaz',
    'Jarir District',
    'Al Rajhi Grand Mosque',
    'Harun ar Rashid Road',
    'An Naseem',
    'Hassan Bin Thabit Street',
    'Khashm Al An',
  ],
  'Yellow': [
    'KAFD',
    'Ar Rabi',
    'Uthman Bin Affan Road',
    'SABIC',
    'PNU 1',
    'PNU 2',
    'Airport T5',
    'Airport T3-4',
    'Airport T1-2',
  ],
  'Green': [
    'Ministry of Education',
    'King Salman Park',
    'As Sulimaniyah',
    'Ad Dhabab',
    'Abu Dhabi square',
    'Officers Club',
    'GOSI',
    'Al Wizarat',
    'Ministry of Defence',
    'King Abdulaziz Hospital',
    'Ministry of Finance',
    'National Museum',
  ],
  'Purple': [
    'KAFD',
    'Ar Rabi',
    'Uthman Bin Affan Road',
    'SABIC',
    'Granadia',
    'Al Yarmuk',
    'Al Hamra',
    'Al Andalus',
    'Khurais Road',
    'As Salam',
    'An Naseem',
  ],
};

/// Build a reverse index: station EN -> set of lines that contain it
Map<String, Set<String>> _buildStationToLines(
  Map<String, List<String>> data,
) {
  final Map<String, Set<String>> idx = {};
  data.forEach((line, stations) {
    for (final st in stations) {
      idx.putIfAbsent(st, () => <String>{}).add(line);
    }
  });
  return idx;
}

/// Global reverse index used for cross-line synchronization.
final Map<String, Set<String>> _stationToLines =
    _buildStationToLines(riyadhMetroStationsEn);

/// AR line labels for UI (keys must match EN canonical line names above).
const Map<String, String> _lineLabelAr = {
  'Blue': 'الأزرق',
  'Red': 'الأحمر',
  'Orange': 'البرتقالي',
  'Yellow': 'الأصفر',
  'Green': 'الأخضر',
  'Purple': 'البنفسجي',
};

/// AR station labels for UI (keys must match EN canonical station names).
const Map<String, String> _stationLabelAr = {
  // Blue
  'SAB Bank': 'بنك الأول',
  'DR SULAIMAN AL HABIB': 'د. سليمان الحبيب',
  'KAFD': 'المركز المالي',
  'Al Murooj': 'المروج',
  'King Fahd District': 'حي الملك فهد',
  'King Fahd District 2': 'حي الملك فهد 2',
  'STC': 'STC',
  'Al Wurud 2': 'الورود 2',
  'Al Urubah': 'العروبة',
  'Alinma Bank': 'مصرف الإنماء',
  'Bank Albilad': 'بنك البلاد',
  'King Fahd Library': 'مكتبة الملك فهد',
  'Ministry of Interior': 'وزارة الداخلية',
  'Al Muorabba': 'المربع',
  'Passport Department': 'الجوازات',
  'National Museum': 'المتحف الوطني',
  'Al Batha': 'البطحاء',
  'Qasr Al Hokm': 'قصر الحكم',
  'Al Owd': 'العود',
  'Skirinah': 'سكيرينة',
  'Manfouhah': 'منفوحة',
  'Al Iman Hospital': 'مستشفى الإيمان',
  'Transportation Center': 'مركز النقل العام',
  'Al Aziziah': 'العزيزية',
  'Ad Dar Al Baida': 'الدار البيضاء',
  // Red
  'King Saud University': 'جامعة الملك سعود',
  'King Salman Oasis': 'واحة الملك سلمان',
  'KACST': 'المدينة التقنية',
  'At Takhassussi': 'التخصصي',
  'Al Wurud': 'الورود',
  'King Abdulaziz Road': 'طريق الملك عبدالعزيز',
  'Ministry of Education': 'وزارة التعليم',
  'An Nuzhah': 'النزهة',
  'Riyadh Exhibition Center': 'مركز الرياض للمعارض',
  'Khalid Bin Alwaleed Road': 'طريق خالد بن الوليد',
  'Al Hamra': 'الحمراء',
  'Al khaleej': 'الخليج',
  'Ishbiliyah': 'إشبيلية',
  'King Fahd Sport City': 'مدينة الملك فهد الرياضية',
  // Orange
  'Jeddah Road': 'طريق جدة',
  'Tuwaiq': 'طويق',
  'Ad Douh': 'الدوح',
  'Aishah bint Abi Bakr Street': 'شارع عائشة بنت أبي بكر',
  'Dhahrat Al Badiah': 'ظهرة البديعة',
  'Sultanah': 'سلطانة',
  'Al Jarradiyah': 'الجرادية',
  'Courts Complex': 'مجمع المحاكم',
  'Al Hilla': 'الحلة',
  'Al Margab': 'المرقب',
  'As Salhiyah': 'الصالحية',
  'First Industrial City': 'المدينة الصناعية الأولى',
  'Railway': 'سكة الحديد',
  'Al Malaz': 'الملز',
  'Jarir District': 'حي جرير',
  'Al Rajhi Grand Mosque': 'جامع الراجحي',
  'Harun ar Rashid Road': 'طريق هارون الرشيد',
  'An Naseem': 'النسيم',
  'Hassan Bin Thabit Street': 'شارع حسان بن ثابت',
  'Khashm Al An': 'خشم العان',
  // Yellow
  'Ar Rabi': 'الربيع',
  'Uthman Bin Affan Road': 'طريق عثمان بن عفان',
  'SABIC': 'سابك',
  'PNU 1': 'جامعة الأميرة نورة 1',
  'PNU 2': 'جامعة الأميرة نورة 2',
  'Airport T5': 'المطار صالة 5',
  'Airport T3-4': 'المطار صالات 3-4',
  'Airport T1-2': 'المطار صالات 1-2',
  // Green
  'King Salman Park': 'حديقة الملك سلمان',
  'As Sulimaniyah': 'السليمانية',
  'Ad Dhabab': 'الضباب',
  'Abu Dhabi square': 'ميدان أبو ظبي',
  'Officers Club': 'نادي الضباط',
  'GOSI': 'التأمينات الاجتماعية',
  'Al Wizarat': 'الوزارات',
  'Ministry of Defence': 'وزارة الدفاع',
  'King Abdulaziz Hospital': 'مستشفى الملك عبدالعزيز',
  'Ministry of Finance': 'وزارة المالية',
  // Purple
  'Granadia': 'غرناطة',
  'Al Yarmuk': 'اليرموك',
  'Al Andalus': 'الأندلس',
  'Khurais Road': 'طريق خريص',
  'As Salam': 'السلام',
};

// -----------------------------------------------------------------------------
// Controller
// -----------------------------------------------------------------------------

/// Controller that holds metro selections and cross-line syncing.
class MetroSelectionController {
  final Map<String, bool> selectedLines = {
    'Blue': false,
    'Red': false,
    'Orange': false,
    'Yellow': false,
    'Green': false,
    'Purple': false,
  };

  final Map<String, Set<String>> selectedStationsByLine = {
    'Blue': <String>{},
    'Red': <String>{},
    'Orange': <String>{},
    'Yellow': <String>{},
    'Green': <String>{},
    'Purple': <String>{},
  };

  /// Lines currently chosen (localized)
  List<String> chosenLinesLocalized(BuildContext context) {
    final isAr =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return selectedLines.entries.where((e) => e.value).map((e) {
      if (isAr) {
        return _lineLabelAr[e.key] ?? e.key; // Arabic label if available
      }
      return e.key; // Default English
    }).toList();
  }

  /// Lines currently chosen (EN).
  List<String> get chosenLines =>
      selectedLines.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Stations by line that will be saved (EN).
  Map<String, List<String>> get chosenStationsByLine {
    final out = <String, List<String>>{};
    for (final line in selectedStationsByLine.keys) {
      final selected = selectedStationsByLine[line]!;
      if (selected.isNotEmpty && (selectedLines[line] ?? false)) {
        out[line] = selected.toList();
      }
    }
    return out;
  }

  void clearLine(String line) {
    selectedLines[line] = false;
    selectedStationsByLine[line]?.clear();
  }

  void setLine(String line, bool value) {
    selectedLines[line] = value;
    if (!value) selectedStationsByLine[line]?.clear();
  }

  void setStation(String line, String station, bool selected) {
    final set = selectedStationsByLine[line]!;
    if (selected) {
      set.add(station);
    } else {
      set.remove(station);
    }
  }

  /// Select/deselect a station AND sync across all lines that contain it.
  /// - On select: ensures all related lines are marked selected and station added.
  /// - On deselect: removes from all related lines (keeps lines selected state as-is).
  void setStationWithIntersections(String line, String station, bool selected) {
    final lines = _stationToLines[station] ?? {line};
    for (final ln in lines) {
      if (selected) {
        selectedLines[ln] = true; // show other lines in UI
      }
      setStation(ln, station, selected);
    }
  }
}

// -----------------------------------------------------------------------------
// Line metadata (colors + tips)
// -----------------------------------------------------------------------------

/// Line brand colors (transit-style).
final Map<String, Color> _lineColor = {
  'Blue': const Color(0xFF0072CE),
  'Red': const Color(0xFFE10600),
  'Orange': const Color(0xFFF36C21),
  'Yellow': const Color(0xFFF9B000),
  'Green': const Color(0xFF009739),
  'Purple': const Color(0xFF6A1B9A),
};

/// Main corridor tips per line (EN/AR).
final Map<String, Map<String, String>> _lineMainTip = {
  'Blue': {
    'en': 'Main corridor: Olaya — Ad Dar Al Baida (North–South).',
    'ar': 'المسار الرئيسي: العليا – الدار البيضاء (شمال–جنوب).',
  },
  'Red': {
    'en': 'Main corridor: King Abdullah Road (East–West).',
    'ar': 'المسار الرئيسي: طريق الملك عبدالله (شرق–غرب).',
  },
  'Orange': {
    'en':
        'Main corridor: Al Madinah Al Munawwarah Rd — Prince Saad bin Abdulrahman I (East–West).',
    'ar':
        'المسار الرئيسي: طريق المدينة المنورة – الأمير سعد بن عبد الرحمن الأول (شرق–غرب).',
  },
  'Yellow': {
    'en': 'Main corridor: Airport Road to KKIA Terminals.',
    'ar': 'المسار الرئيسي: طريق المطار حتى صالات مطار الملك خالد.',
  },
  'Green': {
    'en': 'Main corridor: King Abdulaziz Road (North–South).',
    'ar': 'المسار الرئيسي: طريق الملك عبدالعزيز (شمال–جنوب).',
  },
  'Purple': {
    'en': 'Main corridor: Khurais Road and eastern districts (East–West).',
    'ar': 'المسار الرئيسي: طريق خريص والمناطق الشرقية (شرق–غرب).',
  },
};

// -----------------------------------------------------------------------------
// Helpers for bilingual search (NEW)
// -----------------------------------------------------------------------------

String _normalize(String s) {
  // Lowercase + strip Arabic diacritics and tatweel for robust matching
  final lower = s.toLowerCase();
  final noTatweel = lower.replaceAll('\u0640', ''); // tatweel
  final noDiacritics = noTatweel.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  return noDiacritics.trim();
}

/// Return both EN and AR labels for a station (always available even if AR missing)
List<String> _labelsForStation(String stEn) {
  final en = stEn;
  final ar = _stationLabelAr[stEn] ?? stEn; // fall back to EN if AR missing
  return [en, ar];
}

// -----------------------------------------------------------------------------
// Widget
// -----------------------------------------------------------------------------

class RiyadhMetroPicker extends StatefulWidget {
  const RiyadhMetroPicker({
    Key? key,
    required this.controller,
    required this.isVisible,
    this.onChanged, // NEW: parent callback
  }) : super(key: key);

  final MetroSelectionController controller;
  final bool isVisible;
  final VoidCallback? onChanged; // NEW

  @override
  State<RiyadhMetroPicker> createState() => _RiyadhMetroPickerState();
}

class _RiyadhMetroPickerState extends State<RiyadhMetroPicker> {
  /// Per-line search controllers (so search is inside each line panel).
  final Map<String, TextEditingController> _lineSearchCtrls = {
    for (final k in riyadhMetroStationsEn.keys) k: TextEditingController()
  };

  /// Track which line panel is expanded.
  final Set<String> _expanded = <String>{};

  @override
  void dispose() {
    for (final c in _lineSearchCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isArabic(BuildContext context) {
    try {
      final code = Localizations.localeOf(context).languageCode.toLowerCase();
      return code == 'ar';
    } catch (_) {
      return Directionality.of(context) == TextDirection.rtl;
    }
  }

  String _displayLine(String lineEn, BuildContext context) {
    return _isArabic(context) ? (_lineLabelAr[lineEn] ?? lineEn) : lineEn;
  }

  String _displayStation(String stEn, BuildContext context) {
    return _isArabic(context) ? (_stationLabelAr[stEn] ?? stEn) : stEn;
  }

  bool _isInterchange(String station) =>
      (_stationToLines[station]?.length ?? 0) > 1;

  int _selectedCountForLine(String line) =>
      (widget.controller.selectedStationsByLine[line]?.length ?? 0);

  int _totalSelectedStations() =>
      widget.controller.selectedStationsByLine.values
          .fold<int>(0, (prev, set) => prev + set.length);

  /// Bilingual filter (FIXED):
  /// - Always matches against BOTH EN canonical and AR label, regardless of locale
  /// - Also normalizes Arabic diacritics/tatweel for robust matching
  List<String> _filteredStations(String line, String query) {
    final all = riyadhMetroStationsEn[line] ?? const <String>[];
    final q = _normalize(query);
    if (q.isEmpty) return all;
    return all.where((sEn) {
      final labels = _labelsForStation(sEn);
      return labels.any((label) => _normalize(label).contains(q));
    }).toList();
  }

  void _selectAll(String line) {
    for (final st in riyadhMetroStationsEn[line] ?? const <String>[]) {
      widget.controller.setStationWithIntersections(line, st, true);
    }
    setState(() {});
    widget.onChanged?.call(); // notify parent
  }

  void _clearAll(String line) {
    for (final st in List<String>.from(
        widget.controller.selectedStationsByLine[line] ?? const <String>[])) {
      widget.controller.setStationWithIntersections(line, st, false);
    }
    setState(() {});
    widget.onChanged?.call(); // notify parent
  }

  Widget _mainLineTip(String line, bool isAr, Color color) {
    final text = _lineMainTip[line]?[isAr ? 'ar' : 'en'] ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Your original per-station interchange tips (restored).
  Widget _interchangeTips(
      String line, List<String> stationsEn, bool isAr, Color color) {
    final List<Widget> tips = [];

    void addTip(bool condition, String ar, String en) {
      if (!condition) return;
      tips.add(
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.transfer_within_a_station,
                  size: 16, color: color.withOpacity(0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAr ? ar : en,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    addTip(
      stationsEn.contains('KAFD'),
      'تنبيه: المركز المالي متصل بالخطوط الأزرق والأصفر والبنفسجي.',
      'Tip: KAFD is connected to Blue, Yellow, and Purple lines.',
    );
    addTip(
      stationsEn.contains('Ar Rabi'),
      'تنبيه: الربيع متصل بالخطين الأصفر والبنفسجي.',
      'Tip: Ar Rabi is connected to Yellow and Purple lines.',
    );
    addTip(
      stationsEn.contains('Uthman Bin Affan Road'),
      'تنبيه: طريق عثمان بن عفان متصل بالخطين الأصفر والبنفسجي.',
      'Tip: Uthman Bin Affan Road is connected to Yellow and Purple lines.',
    );
    addTip(
      stationsEn.contains('SABIC'),
      'تنبيه: سابك متصلة بالخطين الأصفر والبنفسجي.',
      'Tip: SABIC is connected to Yellow and Purple lines.',
    );
    addTip(
      stationsEn.contains('STC'),
      'تنبيه: STC متصلة بالخطين الأحمر والأزرق.',
      'Tip: STC is connected to Red and Blue lines.',
    );
    addTip(
      stationsEn.contains('National Museum'),
      'تنبيه: المتحف الوطني متصل بالخطين الأزرق والأخضر.',
      'Tip: National Museum is connected to Green and Blue lines.',
    );
    addTip(
      stationsEn.contains('Qasr Al Hokm'),
      'تنبيه: قصر الحكم متصل بالخطين الأزرق والبرتقالي.',
      'Tip: Qasr Al Hokm is connected to Orange and Blue lines.',
    );
    addTip(
      stationsEn.contains('Ministry of Education'),
      'تنبيه: وزارة التعليم متصلة بالخطين الأحمر والأخضر.',
      'Tip: Ministry of Education is connected to Red and Green lines.',
    );
    addTip(
      stationsEn.contains('Al Hamra'),
      'تنبيه: الحمراء متصلة بالخطين الأحمر والبنفسجي.',
      'Tip: Al Hamra is connected to Red and Purple lines.',
    );
    addTip(
      stationsEn.contains('An Naseem'),
      'تنبيه: النسيم متصلة بالخطين البرتقالي والبنفسجي.',
      'Tip: An Naseem is connected to Orange and Purple lines.',
    );

    if (tips.isEmpty) return const SizedBox.shrink();
    return Column(children: tips);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    final isAr = _isArabic(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        30.kH,
        const ReusedProviderEstateContainer(
          hint: "Nearby Riyadh Metro (Optional)",
        ),

        // Header: lines and selected count
        8.kH,
        Container(
          margin: const EdgeInsetsDirectional.only(start: 30, end: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_subway_filled_rounded,
                        color: kDeepPurpleColor),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? "خطوط المترو" : "Metro Lines",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kDeepPurpleColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isAr
                            ? "محطات محددة: ${_totalSelectedStations()}"
                            : "Selected: ${_totalSelectedStations()}",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: kDeepPurpleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                10.kH,
                // Horizontal line pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: riyadhMetroStationsEn.keys.map((line) {
                      final selected = widget.controller.selectedLines[line]!;
                      final color = _lineColor[line] ?? kDeepPurpleColor;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          avatar: CircleAvatar(
                            radius: 8,
                            backgroundColor: color,
                          ),
                          label: Text(
                            _displayLine(line, context),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                            ),
                          ),
                          selected: selected,
                          selectedColor: color,
                          backgroundColor: color.withOpacity(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 0.28
                                  : 0.12),
                          onSelected: (v) {
                            setState(() {
                              widget.controller.setLine(line, v);
                              if (v) {
                                _expanded.add(line);
                              } else {
                                _expanded.remove(line);
                                _lineSearchCtrls[line]!.clear();
                              }
                            });
                            widget.onChanged?.call(); // notify parent
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Per-line panels
        14.kH,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 50, end: 20),
          child: Column(
            children: riyadhMetroStationsEn.keys
                .where((line) => widget.controller.selectedLines[line] == true)
                .map((line) {
              final color = _lineColor[line] ?? kDeepPurpleColor;
              final query = _lineSearchCtrls[line]!.text;
              final filtered = _filteredStations(line, query);
              final selectedSet =
                  widget.controller.selectedStationsByLine[line]!;
              final isOpen = _expanded.contains(line);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.06),
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    child: Column(
                      children: [
                        // Header
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isOpen) {
                                _expanded.remove(line);
                              } else {
                                _expanded.add(line);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: color, width: 6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayLine(line, context),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      2.kH,
                                      Text(
                                        isAr
                                            ? "${filtered.length} محطة • المحدد ${selectedSet.length}"
                                            : "${filtered.length} stations • selected ${selectedSet.length}",
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isOpen)
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: _mainLineTip(line, isAr, color),
                          ),

                        // 🔎 Per-line search (bilingual)
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: TextField(
                              controller: _lineSearchCtrls[line],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _lineSearchCtrls[line]!.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _lineSearchCtrls[line]!.clear();
                                          setState(() {});
                                        },
                                      ),
                                hintText: isAr
                                    ? "ابحث داخل محطات هذا الخط…"
                                    : "Search within this line…",
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.grey.withOpacity(0.08),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),

                        // Actions row
                        if (isOpen)
                          Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                // TextButton.icon(
                                //   onPressed: () => _selectAll(line),
                                //   icon: Icon(Icons.select_all, color: color),
                                //   label: Text(
                                //     isAr ? "تحديد الكل" : "Select all",
                                //     style: TextStyle(color: color),
                                //   ),
                                //   style: TextButton.styleFrom(
                                //     foregroundColor: color,
                                //   ),
                                // ),
                                TextButton.icon(
                                  onPressed: () => _clearAll(line),
                                  icon: Icon(Icons.clear_all, color: color),
                                  label: Text(
                                    isAr ? "مسح" : "Clear",
                                    style: TextStyle(color: color),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: color,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Stations grid (chips)
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filtered.map((stEn) {
                                final bool isSel = selectedSet.contains(stEn);
                                final bool inter = _isInterchange(stEn);

                                return FilterChip(
                                  avatar: inter
                                      ? Icon(Icons.sync_alt,
                                          size: 16,
                                          color: isSel
                                              ? Colors.white
                                              : color.withOpacity(0.9))
                                      : null,
                                  label: Text(_displayStation(stEn, context)),
                                  selected: isSel,
                                  checkmarkColor: Colors.white,
                                  selectedColor: color.withOpacity(0.85),
                                  backgroundColor: color.withOpacity(
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? 0.24
                                          : 0.12),
                                  labelStyle: TextStyle(
                                    color: isSel
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                      color: color.withOpacity(0.35)),
                                  onSelected: (v) {
                                    setState(() {
                                      // Keep mutual stations in sync across lines
                                      widget.controller
                                          .setStationWithIntersections(
                                              line, stEn, v);
                                    });
                                    widget.onChanged?.call(); // notify parent
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                        // Interchange tips (below chips)
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: _interchangeTips(line,
                                riyadhMetroStationsEn[line]!, isAr, color),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
