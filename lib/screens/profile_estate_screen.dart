import 'package:auto_size_text/auto_size_text.dart';
import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/screens/edit_estate_hotel_screen.dart';
import 'package:daimond_host_provider/screens/qr_image_screen.dart';
import 'package:daimond_host_provider/animations_widgets/build_shimmer_loader.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/booking_services.dart';
import '../backend/estate_services.dart';
import '../constants/coffee_music_options.dart';
import '../constants/entry_options.dart';
import '../constants/hotel_entry_options.dart';
import '../constants/restaurant_options.dart';
import '../constants/sessions_options.dart';
import '../localization/language_constants.dart';
import '../backend/customer_rate_services.dart';
import '../state_management/general_provider.dart';
import '../utils/rooms.dart';
import '../utils/success_dialogue.dart';
import '../utils/failure_dialogue.dart';
import '../widgets/chip_widget.dart';
import '../widgets/full_screen_image_widget.dart';
import '../widgets/reused_elevated_button.dart';
import 'edit_estate_screen.dart';
import 'estate_chat_screen.dart';

class ProfileEstateScreen extends StatefulWidget {
  final String nameEn;
  final String nameAr;
  final String bioEn;
  final String bioAr;
  final String estateId;
  final String estateType;
  final String location;
  final double rating;
  final String fee;
  final String deliveryTime;
  final double price;
  final String typeOfRestaurant;
  final String sessions;
  final String menuLink;
  final String entry;
  final String music;
  final double lat;
  final double lon;
  final String type;
  final String hasKidsArea;
  final String hasValet;
  final String valetWithFees;
  final String hasSwimmingPool;
  final String hasGym;
  final String hasBarber;
  final String hasMassage;
  final String isSmokingAllowed;
  final String hasJacuzziInRoom;
  final String lstMusic;
  final String? branchEn;
  final String? branchAr;

  const ProfileEstateScreen(
      {Key? key,
      required this.nameEn,
      required this.nameAr,
      required this.estateId,
      required this.estateType,
      required this.location,
      required this.rating,
      required this.fee,
      required this.deliveryTime,
      required this.price,
      required this.typeOfRestaurant,
      required this.sessions,
      required this.menuLink,
      required this.entry,
      required this.music,
      required this.lat,
      required this.lon,
      required this.bioAr,
      required this.type,
      required this.bioEn,
      required this.isSmokingAllowed,
      required this.hasGym,
      required this.hasMassage,
      required this.hasBarber,
      required this.hasSwimmingPool,
      required this.hasKidsArea,
      required this.hasJacuzziInRoom,
      required this.valetWithFees,
      required this.hasValet,
      required this.lstMusic,
      required this.branchEn,
      required this.branchAr})
      : super(key: key);

  @override
  _ProfileEstateScreenState createState() => _ProfileEstateScreenState();
}

class _ProfileEstateScreenState extends State<ProfileEstateScreen> {
  List<String> _imageUrls = [];
  List<Rooms> LstRoomsSelected = [];
  Map<String, dynamic> estate = {};
  List<Rooms> LstRooms = [];
  bool isLoading = true;
  double _overallRating = 0.0;
  final _cacheManager = CacheManager(
      Config('customCacheKey', stalePeriod: const Duration(days: 7)));
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _feedbackList = [];

  // ===== Metro helpers (colors + AR labels) =====
  final Map<String, Color> _lineColors = const {
    'Blue': Color(0xFF0072CE),
    'Green': Color(0xFF2E7D32),
    'Red': Color(0xFFD32F2F),
    'Yellow': Color(0xFFF9A825),
    'Orange': Color(0xFFEF6C00),
    'Purple': Color(0xFF6A1B9A),
  };

  final Map<String, String> _lineLabelAr = const {
    'Blue': 'الأزرق',
    'Red': 'الأحمر',
    'Orange': 'البرتقالي',
    'Yellow': 'الأصفر',
    'Green': 'الأخضر',
    'Purple': 'البنفسجي',
  };

  // AR station labels (subset; includes ones from your examples)
  final Map<String, String> _stationLabelAr = {
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

  bool _isArabic() {
    try {
      return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    } catch (_) {
      return Directionality.of(context) == TextDirection.RTL;
    }
  }

  String _displayLineLabel(String line) =>
      _isArabic() ? (_lineLabelAr[line] ?? line) : line;

  String _displayStationLabel(String st) =>
      _isArabic() ? (_stationLabelAr[st] ?? st) : st;

  @override
  void initState() {
    super.initState();
    _listenToEstateData();
    _fetchImageUrls();
    _fetchUserRatings();
    _fetchFeedback();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    DatabaseReference roomsRef = FirebaseDatabase.instance
        .ref('App/Estate/Hottel/${widget.estateId}/Rooms');

    final snapshot = await roomsRef.get();
    List<Rooms> roomsTemp = [];
    if (snapshot.exists && snapshot.value != null) {
      Map data = snapshot.value as Map;
      data.forEach((key, value) {
        Rooms room = Rooms(
          id: value["ID"] ?? "",
          name: value["Name"] ?? "",
          nameEn: value["NameEn"] ?? "",
          price: value["Price"] ?? "",
          bio: value["BioAr"] ?? "",
          bioEn: value["BioEn"] ?? "",
          color: Colors.white,
        );
        roomsTemp.add(room);
      });
    }

    setState(() {
      LstRooms = roomsTemp;
    });
  }

  void _listenToEstateData() {
    String estateTypePath;
    switch (widget.estateType) {
      case "1":
        estateTypePath = "Hottel";
        break;
      case "2":
        estateTypePath = "Coffee";
        break;
      case "3":
        estateTypePath = "Restaurant";
        break;
      default:
        estateTypePath = widget.estateType;
    }

    DatabaseReference estateRef = FirebaseDatabase.instance
        .ref('App/Estate/$estateTypePath/${widget.estateId}');

    estateRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        setState(() {
          estate = Map<String, dynamic>.from(event.snapshot.value as Map);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _fetchEstateData() async {
    try {
      String estateTypePath;
      switch (widget.estateType) {
        case "1":
          estateTypePath = "Hottel";
          break;
        case "2":
          estateTypePath = "Coffee";
          break;
        case "3":
          estateTypePath = "Restaurant";
          break;
        default:
          estateTypePath = widget.estateType;
      }

      DatabaseReference estateRef = FirebaseDatabase.instance
          .ref('App/Estate/$estateTypePath/${widget.estateId}');

      DataSnapshot snapshot = await estateRef.get();

      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          estate = Map<String, dynamic>.from(snapshot.value as Map);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.orange, size: size);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.orange, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.orange, size: size);
        }
      }),
    );
  }

  Future<List<String>> fetchExistingImages() async {
    List<String> existingImages = [];
    try {
      final storageRef = FirebaseStorage.instance.ref().child(widget.estateId);
      final ListResult result = await storageRef.listAll();

      for (var item in result.items) {
        existingImages.add(item.name);
      }

      existingImages.sort((a, b) {
        int numA = int.tryParse(a.split('.').first) ?? 0;
        int numB = int.tryParse(b.split('.').first) ?? 0;
        return numA.compareTo(numB);
      });

      return existingImages;
    } catch (e) {
      return [];
    }
  }

  /// Try to load `ImageUrls` from RTDB first; if missing, fall back to Storage.
  Future<void> _fetchImageUrls() async {
    try {
      String typePath = widget.estateType == "1"
          ? "Hottel"
          : (widget.estateType == "2" ? "Coffee" : "Restaurant");
      final dbRef = FirebaseDatabase.instance
          .ref("App/Estate/$typePath/${widget.estateId}/ImageUrls");
      final snapshot = await dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final List<dynamic> dbList = List<dynamic>.from(snapshot.value as List);
        setState(() => _imageUrls = dbList.cast<String>());
        return;
      }
    } catch (e) {
      // fall through
    }

    List<String> storageUrls = [];
    try {
      final existing = await fetchExistingImages();
      for (var name in existing) {
        final url = await FirebaseStorage.instance
            .ref("${widget.estateId}/$name")
            .getDownloadURL();
        storageUrls.add(url);
      }
    } catch (e) {}
    setState(() => _imageUrls = storageUrls);
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: _imageUrls,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Future<void> _fetchUserRatings() async {
    CustomerRateServices rateServices = CustomerRateServices();
    final ratings =
        await rateServices.fetchEstateRatingWithUsers(widget.estateId);
    double totalRating = ratings.isNotEmpty
        ? ratings.map((e) => e['rating'] as double).reduce((a, b) => a + b) /
            ratings.length
        : 0.0;

    setState(() {
      _overallRating = totalRating;
    });
  }

  Future<void> _fetchFeedback() async {
    try {
      DatabaseReference feedbackRef =
          FirebaseDatabase.instance.ref('App/CustomerFeedback');
      DataSnapshot snapshot = await feedbackRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> feedbacks = [];
        snapshot.children.forEach((child) {
          final data = Map<String, dynamic>.from(child.value as Map);
          if (data['EstateID'] == widget.estateId) {
            feedbacks.add(data);
          }
        });
        setState(() {
          _feedbackList = feedbacks;
        });
      }
    } catch (e) {}
  }

  void _launchMaps() async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lon}';
    try {
      await launch(googleUrl, forceWebView: false);
    } catch (e) {}
  }

  // ====== Metro: parse and render ======
  List<String> _parseStations(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    // comma-separated
    return raw
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _hasMetroData(Map<String, dynamic>? metro) {
    if (metro == null) return false;
    final lines = metro['Lines'];
    if (lines is! Map) return false;
    for (final entry in lines.entries) {
      final stations = _parseStations(entry.value['Stations']);
      if (stations.isNotEmpty) return true;
    }
    return false;
  }

  Widget _buildMetroSection(Map<String, dynamic> metro) {
    final isAr = _isArabic();
    final linesMap = (metro['Lines'] ?? {}) as Map;
    final List<Widget> lineCards = [];

    for (final MapEntry entry in linesMap.entries) {
      final String lineName = entry.key.toString();
      final dynamic node = entry.value;
      final List<String> stations =
          _parseStations(node is Map ? node['Stations'] : null);
      if (stations.isEmpty) continue;

      final Color lineColor = _lineColors[lineName] ?? kDeepPurpleColor;

      lineCards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: lineColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lineColor.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: lineColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? (_lineLabelAr[lineName] ?? lineName) : lineName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stations
                      .map(
                        (st) => Chip(
                          label: Text(_displayStationLabel(st)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: lineColor.withOpacity(0.35)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (lineCards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.kH,
        Text(
          getTranslated(context, "Nearby Riyadh Metro"),
          style: kTeritary.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        8.kH,
        Column(children: lineCards),
      ],
    );
  }

  // ===== Translation helpers for existing chips =====
  String getTranslatedTypeOfRestaurant(BuildContext context, String types) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();
    List translatedTypes = typeList.map((type) {
      final match = restaurantOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type},
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();
    return translatedTypes.join(', ');
  }

  String getTranslatedSessions(BuildContext context, String types) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    Map<String, String> uiMapping = {
      'Internal sessions': 'Indoor sessions',
      'External sessions': 'Outdoor sessions'
    };
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();
    List translatedTypes = typeList.map((type) {
      if (!isArabic && uiMapping.containsKey(type)) {
        return uiMapping[type]!;
      }
      final match = sessionsOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type},
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();
    return translatedTypes.join(', ');
  }

  String getTranslatedHotelEntry(BuildContext context, String types) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();
    List translatedTypes = typeList.map((type) {
      final match = hotelEntryOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type},
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();
    return translatedTypes.join(', ');
  }

  String getTranslatedEntry(BuildContext context, String types) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();
    List translatedTypes = typeList.map((type) {
      final match = entryOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type},
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();
    return translatedTypes.join(', ');
  }

  String getTranslatedCoffeeMusicOptions(BuildContext context, String types) {
    bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    List<String> typeList =
        types.split(',').map((type) => type.trim()).toList();
    List translatedTypes = typeList.map((type) {
      final match = coffeeMusicOptions.firstWhere(
        (option) => option['label'] == type,
        orElse: () => {'label': type, 'labelAr': type},
      );
      return isArabic ? match['labelAr'] : match['label'];
    }).toList();
    return translatedTypes.join(', ');
  }

  void _showOptionsList(String title, List<Map<String, dynamic>> options) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    List<Map<String, dynamic>> estateOptions = [];

    if (title == getTranslated(context, "Type of Restaurant")) {
      estateOptions = restaurantOptions
          .where((option) {
            return estate['TypeofRestaurant']?.contains(option['label']) ??
                false;
          })
          .cast<Map<String, dynamic>>()
          .toList();
    } else if (title == getTranslated(context, "Sessions")) {
      estateOptions = sessionsOptions
          .where((option) {
            return estate['Sessions']?.contains(option['label']) ?? false;
          })
          .cast<Map<String, dynamic>>()
          .toList();
    } else if (title == getTranslated(context, "Entry")) {
      estateOptions = entryOptions
          .where((option) {
            return estate['Entry']?.contains(option['label']) ?? false;
          })
          .cast<Map<String, dynamic>>()
          .toList();
    } else if (title == getTranslated(context, "Hotel Entry")) {
      final entries =
          (estate['Entry'] ?? '').split(',').map((e) => e.trim()).toList();
      estateOptions = hotelEntryOptions
          .where((option) => entries.contains(option['label']))
          .toList();
    } else if (title == getTranslated(context, "Music")) {
      estateOptions = coffeeMusicOptions
          .where((option) {
            return estate['Lstmusic']?.contains(option['label']) ?? false;
          })
          .cast<Map<String, dynamic>>()
          .toList();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: estateOptions.length,
                  itemBuilder: (context, index) {
                    final option = estateOptions[index];
                    String displayLabel = isArabic
                        ? option['labelAr'] ?? option['label']
                        : option['label'] ?? "";
                    if (!isArabic &&
                        title == getTranslated(context, "Sessions")) {
                      if (displayLabel == "Internal sessions") {
                        displayLabel = "Indoor sessions";
                      } else if (displayLabel == "External sessions") {
                        displayLabel = "Outdoor sessions";
                      }
                    }
                    return ListTile(title: Text(displayLabel));
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;

// get name from RTDB or from widget
    final String baseName = languageCode == 'ar'
        ? (estate['NameAr'] ?? widget.nameAr)
        : (estate['NameEn'] ?? widget.nameEn);

// get branch from RTDB if available, otherwise from widget
    final String branch = languageCode == 'ar'
        ? ((estate['BranchAr'] ?? widget.branchAr) ?? '')
        : ((estate['BranchEn'] ?? widget.branchEn) ?? '');

// final display
    final String displayName =
        branch.trim().isNotEmpty ? '$baseName - ${branch.trim()}' : baseName;

    final String displayBio = languageCode == 'ar'
        ? (estate['BioAr'] ?? widget.bioAr)
        : (estate['BioEn'] ?? widget.bioEn);
    final objProvider = Provider.of<GeneralProvider>(context, listen: true);

    final Map<String, dynamic>? metro = estate['Metro'] == null
        ? null
        : Map<String, dynamic>.from(estate['Metro'] as Map);

    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: kDeepPurpleColor),
            onPressed: _launchMaps,
          ),
          if (widget.estateType != "1")
            IconButton(
              icon: const Icon(Icons.edit, color: kDeepPurpleColor),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EditEstate(
                    objEstate: estate,
                    LstRooms: LstRooms,
                    estateType: widget.estateType,
                    estateId: widget.estateId,
                  ),
                ));
                _fetchEstateData();
                _fetchImageUrls();
              },
            ),
          if (widget.estateType == "1")
            IconButton(
              icon: const Icon(Icons.edit, color: kDeepPurpleColor),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EditEstateHotel(
                    objEstate: estate,
                    LstRooms: LstRooms,
                    estateType: widget.estateType,
                    estateId: widget.estateId,
                  ),
                ));
                _fetchEstateData();
                _fetchImageUrls();
              },
            ),
        ],
      ),
      body: isLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShimmerLoader(),
                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 200,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchImageUrls();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images
                      _imageUrls.isEmpty
                          ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey[200],
                              ),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: PageView.builder(
                                    itemCount: _imageUrls.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () =>
                                            _viewImage(_imageUrls[index]),
                                        child: CachedNetworkImage(
                                          imageUrl: _imageUrls[index],
                                          cacheManager: _cacheManager,
                                          placeholder: (context, url) =>
                                              Container(
                                                  color: Colors.grey[300]),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1} / ${_imageUrls.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: kTeritary.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayBio,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (widget.menuLink.isNotEmpty) ...[
                        InkWell(
                          onTap: () async {
                            final url = widget.menuLink;
                            if (await launch(url, forceWebView: false)) {
                              await launch(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(
                                      context, "Could not open link")),
                                ),
                              );
                            }
                          },
                          child: AutoSizeText(
                            getTranslated(context, "Menu Link"),
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            minFontSize: 12,
                          ),
                        ),
                        8.kH,
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _overallRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ===== Chips (existing) =====
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: [
                          if (widget.type == "3")
                            InfoChip(
                              icon: Icons.fastfood,
                              label: getTranslatedTypeOfRestaurant(
                                context,
                                estate['TypeofRestaurant'] ??
                                    widget.typeOfRestaurant,
                              ),
                              onTap: () => _showOptionsList(
                                getTranslated(context, "Type of Restaurant"),
                                restaurantOptions.cast<Map<String, dynamic>>(),
                              ),
                            ),
                          if (widget.type == "3" || widget.type == "2")
                            InfoChip(
                              icon: Icons.home,
                              label: getTranslatedSessions(
                                context,
                                estate['Sessions'] ?? widget.sessions,
                              ),
                              onTap: () => _showOptionsList(
                                getTranslated(context, "Sessions"),
                                sessionsOptions.cast<Map<String, dynamic>>(),
                              ),
                            ),
                          if (widget.type == "1")
                            InfoChip(
                              icon: Icons.grain,
                              label: getTranslatedHotelEntry(
                                context,
                                estate['Entry'] ?? widget.entry,
                              ),
                              onTap: () {
                                _showOptionsList(
                                  getTranslated(context, "Hotel Entry"),
                                  hotelEntryOptions
                                      .cast<Map<String, dynamic>>(),
                                );
                              },
                            ),
                          if (widget.type != "1")
                            InfoChip(
                              icon: Icons.grain,
                              label: getTranslatedEntry(
                                context,
                                estate['Entry'] ?? widget.entry,
                              ),
                              onTap: () {
                                _showOptionsList(
                                  getTranslated(context, "Entry"),
                                  entryOptions.cast<Map<String, dynamic>>(),
                                );
                              },
                            ),
                          if ((widget.type == "3" || widget.type == "1") &&
                              (estate['Music'] != null &&
                                  estate['Music'] != "" &&
                                  estate['Music'] != "0"))
                            InfoChip(
                              icon: Icons.music_note,
                              label: estate['Music'] == "1"
                                  ? getTranslated(context, "There is music")
                                  : getTranslated(context, "There is no music"),
                            ),
                          if (widget.type == "2" &&
                              (estate['Lstmusic'] != null) &&
                              estate['Lstmusic'].isNotEmpty)
                            InfoChip(
                              icon: Icons.music_note,
                              label: estate['Lstmusic'] != null &&
                                      estate['Lstmusic'].isNotEmpty
                                  ? getTranslatedCoffeeMusicOptions(
                                      context,
                                      estate['Lstmusic'] ?? widget.lstMusic,
                                    )
                                  : getTranslated(context, "There is no music"),
                            ),
                          if (widget.type == "2" &&
                              (estate['Music'] != null &&
                                  estate['Music'] != "" &&
                                  estate['Music'] != "0"))
                            InfoChip(
                              icon: Icons.music_note,
                              label: estate['Music'] == "1"
                                  ? getTranslatedCoffeeMusicOptions(
                                      context,
                                      "Music",
                                    )
                                  : getTranslated(context, "There is no music"),
                            ),
                          if ((widget.type == "2" || widget.type == "3") &&
                              (estate['HasKidsArea'] != null &&
                                  estate['HasKidsArea'] != "" &&
                                  estate['HasKidsArea'] != "0"))
                            InfoChip(
                              icon: Icons.child_care,
                              label: estate['HasKidsArea'] == "1"
                                  ? getTranslated(context, "We have kids area")
                                  : getTranslated(
                                      context, "We don't have kids area"),
                            ),
                          if (widget.type == "1" &&
                              (estate['HasJacuzziInRoom'] != null &&
                                  estate['HasJacuzziInRoom'] != "" &&
                                  estate['HasJacuzziInRoom'] != "0"))
                            InfoChip(
                              icon: Icons.bathtub,
                              label: estate['HasJacuzziInRoom'] == "1"
                                  ? getTranslated(context, "We have jaccuzzi")
                                  : getTranslated(
                                      context, "We don't have jacuzzi"),
                            ),
                          if (estate['HasValet'] == "1")
                            InfoChip(
                              icon: Icons.directions_car,
                              label: getTranslated(
                                  context, "Valet service available"),
                            ),
                          if (estate['HasValet'] == "1" &&
                              estate['ValetWithFees'] == "1")
                            InfoChip(
                              icon: Icons.money,
                              label:
                                  getTranslated(context, "Valet is not free"),
                            ),
                          if (widget.type == "1" &&
                              (estate['HasSwimmingPool'] != null &&
                                  estate['HasSwimmingPool'] != "" &&
                                  estate['HasSwimmingPool'] != "0"))
                            InfoChip(
                              icon: Icons.pool,
                              label: estate['HasSwimmingPool'] == "1"
                                  ? getTranslated(
                                      context, "We have swimming pool")
                                  : getTranslated(
                                      context, "We don't have swimming pool"),
                            ),
                          if (widget.type == "1" &&
                              (estate['HasMassage'] != null &&
                                  estate['HasMassage'] != "" &&
                                  estate['HasMassage'] != "0"))
                            InfoChip(
                              icon: Icons.spa,
                              label: estate['HasMassage'] == "1"
                                  ? getTranslated(context, "We have massage")
                                  : getTranslated(
                                      context, "We don't have massage"),
                            ),
                          if (widget.type == "1" &&
                              (estate['HasGym'] != null &&
                                  estate['HasGym'] != "" &&
                                  estate['HasGym'] != "0"))
                            InfoChip(
                              icon: Icons.fitness_center,
                              label: estate['HasGym'] == "1"
                                  ? getTranslated(context, "We have Gym")
                                  : getTranslated(context, "We don't have gym"),
                            ),
                          if (widget.type == "1" &&
                              (estate['HasBarber'] != null &&
                                  estate['HasBarber'] != "" &&
                                  estate['HasBarber'] != "0"))
                            InfoChip(
                              icon: Icons.content_cut,
                              label: estate['HasBarber'] == "1"
                                  ? getTranslated(context, "We have barber")
                                  : getTranslated(
                                      context, "We don't have barber"),
                            ),
                          if (estate['IsSmokingAllowed'] == "1")
                            InfoChip(
                              icon: Icons.smoking_rooms,
                              label:
                                  getTranslated(context, "Smoking is allowed"),
                            ),
                        ],
                      ),

                      // ===== NEW: Metro section =====
                      if (_hasMetroData(metro)) _buildMetroSection(metro!),

                      const SizedBox(height: 16),
                      Visibility(
                        visible: widget.type == "1",
                        child: AutoSizeText(
                          getTranslated(context, "Rooms"),
                          style: kTeritary,
                          maxLines: 1,
                          minFontSize: 12,
                        ),
                      ),
                      Visibility(
                        visible: widget.type == "1",
                        child: FirebaseAnimatedList(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          query: FirebaseDatabase.instance
                              .ref("App")
                              .child("Estate")
                              .child("Hottel")
                              .child(widget.estateId.toString())
                              .child("Rooms"),
                          itemBuilder: (context, snapshot, animation, index) {
                            Map map = snapshot.value as Map;
                            Rooms room = Rooms(
                              id: map['ID'] ?? "",
                              name: map['Name'] ?? "",
                              nameEn: map['NameEn'] ?? "",
                              price: map['Price'] ?? "",
                              bio: map['BioAr'] ?? "",
                              bioEn: map['BioEn'] ?? "",
                              color: Colors.white,
                            );

                            final displayName = room.name;
                            final String displayBio = languageCode == 'ar'
                                ? (room.bio ?? widget.bioAr)
                                : (room.bioEn ?? widget.bioEn);

                            return GestureDetector(
                              onTap: () {},
                              child: ListTile(
                                title: Text(displayName),
                                subtitle: Text(displayBio),
                                leading: const Icon(Icons.single_bed,
                                    color: Colors.black),
                                trailing: Text(room.price,
                                    style: const TextStyle(
                                        color: kDeepPurpleColor)),
                              ),
                            );
                          },
                        ),
                      ),
                      AutoSizeText(
                        getTranslated(context, "Feedback"),
                        style: kTeritary.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        minFontSize: 12,
                      ),
                      const SizedBox(height: 8),
                      _feedbackList.isEmpty
                          ? Center(
                              child: Text(getTranslated(
                                  context, "No feedback available.")))
                          : SizedBox(
                              height: 300,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _feedbackList.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final feedback = _feedbackList[index];
                                  return SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 4,
                                      margin: EdgeInsets.zero,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor:
                                                      kDeepPurpleColor,
                                                  backgroundImage: feedback[
                                                                  'profileImageUrl'] !=
                                                              null &&
                                                          feedback[
                                                                  'profileImageUrl']
                                                              .toString()
                                                              .isNotEmpty
                                                      ? CachedNetworkImageProvider(
                                                          feedback[
                                                              'profileImageUrl'])
                                                      : null,
                                                  child: feedback['profileImageUrl'] ==
                                                              null ||
                                                          feedback[
                                                                  'profileImageUrl']
                                                              .toString()
                                                              .isEmpty
                                                      ? Text(
                                                          (feedback['userName'] !=
                                                                      null &&
                                                                  (feedback['userName']
                                                                          as String)
                                                                      .isNotEmpty)
                                                              ? (feedback['userName']
                                                                      as String)[0]
                                                                  .toUpperCase()
                                                              : '?',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      AutoSizeText(
                                                        feedback['userName'] ??
                                                            getTranslated(
                                                                context,
                                                                'Anonymous'),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        maxLines: 1,
                                                        minFontSize: 12,
                                                      ),
                                                      Text(
                                                        feedback['feedbackDate'] !=
                                                                null
                                                            ? DateFormat.yMMMd()
                                                                .format(DateTime
                                                                    .parse(feedback[
                                                                        'feedbackDate']))
                                                            : '',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            _buildStarRating(
                                              (feedback['RateForEstate'] ?? 0)
                                                  .toDouble(),
                                              size: 16,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Estate Rating: ${feedback['RateForEstate'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const Divider(),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: AutoSizeText(
                                                  feedback['feedback'] ??
                                                      getTranslated(context,
                                                          'No feedback provided'),
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  maxLines: 10,
                                                  minFontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.restaurant,
                                                            color:
                                                                Colors.orange,
                                                            size: 16),
                                                        const SizedBox(
                                                            width: 4),
                                                        _buildStarRating(
                                                          (feedback['RateForFoodOrDrink'] ??
                                                                  0)
                                                              .toDouble(),
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Food Rating: ${feedback['RateForFoodOrDrink'] ?? 'N/A'}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons
                                                                .miscellaneous_services,
                                                            color:
                                                                Colors.orange,
                                                            size: 16),
                                                        const SizedBox(
                                                            width: 4),
                                                        _buildStarRating(
                                                          (feedback['RateForServices'] ??
                                                                  0)
                                                              .toDouble(),
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Service Rating: ${feedback['RateForServices'] ?? 'N/A'}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      const SizedBox(height: 24),
                      Center(
                        child: CustomButton(
                          text: getTranslated(context, "View your Qr Code"),
                          onPressed: () {
                            if (isLoading) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(context,
                                      'Data is still loading. Please try again shortly.')),
                                ),
                              );
                            } else if (estate.isEmpty ||
                                estate['IDUser'] == null ||
                                estate['NameEn'] == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(getTranslated(context,
                                      'Unable to load QR Code. Please ensure estate data is complete.')),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRImage(
                                    userId: estate['IDUser'],
                                    userName: estate['NameEn'],
                                    estateId: widget.estateId,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
