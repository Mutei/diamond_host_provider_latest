// lib/screens/main_screen_content.dart
// FULL MODIFIED FILE: Only changes are the addition of a FAB that opens ChatBotScreen

import 'dart:async'; // <-- for StreamSubscription

import 'package:daimond_host_provider/constants/colors.dart';
import 'package:daimond_host_provider/constants/styles.dart';
import 'package:daimond_host_provider/extension/sized_box_extension.dart';
import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:daimond_host_provider/animations_widgets/build_shimmer_loader.dart';
import 'package:daimond_host_provider/screens/coffee_screen.dart';
import 'package:daimond_host_provider/screens/restaurant_screen.dart';
import 'package:daimond_host_provider/widgets/reused_appbar.dart';
import 'package:daimond_host_provider/widgets/estate_card_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../animations_widgets/build_shimmer_estate_card.dart';
import '../backend/customer_rate_services.dart';
import '../backend/estate_services.dart';
import '../backend/adding_estate_services.dart';
import '../widgets/custom_category_button.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/search_text_form_field.dart';
import 'chat_bot_screen.dart';
import 'hotel_screen.dart';
import 'profile_estate_screen.dart';
import 'maps_screen.dart';

// ---------- small helpers ----------
class _EstateOption {
  final String estateId;
  final String display;
  const _EstateOption({required this.estateId, required this.display});
}

class _PickedScopeResult {
  final bool isAll;
  final String? estateId;
  _PickedScopeResult._(this.isAll, this.estateId);
  factory _PickedScopeResult.all() => _PickedScopeResult._(true, null);
  factory _PickedScopeResult.estate(String estateId) =>
      _PickedScopeResult._(false, estateId);
}

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  _MainScreenContentState createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent>
    with WidgetsBindingObserver {
  final EstateServices estateServices = EstateServices();
  final CustomerRateServices customerRateServices = CustomerRateServices();
  final AddEstateServices backendService = AddEstateServices();
  final List<String> categories = ['Hotel', 'Restaurant', 'Cafe'];

  List<Map<String, dynamic>> estates = [];
  List<Map<String, dynamic>> filteredEstates = [];
  bool isLoading = true;
  bool permissionsChecked = false;
  bool searchActive = false;
  String typeAccount = '';

  String selectedCategory = "All";
  final TextEditingController searchController = TextEditingController();
  String firstName = '';

  // ----- AccessPins state -----
  List<_EstateOption> _estateOptions = const [];
  String? _allPin;
  Map<String, String> _estatePins = const {};
  bool _pinsLoaded = false;

  // Current scope
  bool _scopeAll = false;
  String? _scopeEstateId; // when not ALL
  String? _scopeEstateName;

  // one-time prompts
  bool _ownerFlowHandledOnce = false;
  bool _scopePromptShown = false;
  bool _askedPerEstatePinsThisSession = false;

  // auth subscription (for clearing persisted scope on logout)
  StreamSubscription<User?>? _authSub; // <-- correct type

  // Track last locale so we can re-localize names without hot-restart
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(_filterEstates);

    // Clear persisted scope on logout
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u == null) {
        _clearPersistedScope(); // fire-and-forget
      }
    });

    _checkPermissionsAndFetchData();
    _fetchUserFirstName();
    _fetchUserTypeAccount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = Localizations.localeOf(context);
    // If language changed, rebuild the display names—no hot restart needed
    if (_lastLocale == null ||
        _lastLocale!.languageCode != loc.languageCode ||
        _lastLocale!.countryCode != loc.countryCode) {
      _lastLocale = loc;
      _prepareEstateOptions(); // rebuild names per locale
      _refreshFilteredEstates(); // keep filtering using new display names
      // Also re-localize the persisted scope chip label
      if (!_scopeAll && _scopeEstateId != null) {
        _scopeEstateName = _localizedEstateNameById(_scopeEstateId!);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.removeListener(_filterEstates);
    searchController.dispose();
    _authSub?.cancel(); // <-- cancel subscription
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndFetchData();
    }
  }

  Future<void> _checkPermissionsAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    permissionsChecked = prefs.getBool('permissionsChecked') ?? false;

    if (!permissionsChecked) {
      await _initializePermissions();
      await prefs.setBool('permissionsChecked', true);
    }

    await _fetchEstates(); // load estates (accepted only)
    await _loadPins(); // load AccessPins/{uid}
    _prepareEstateOptions(); // convert estates -> options

    // Try to restore a previously chosen scope (per user)
    await _maybeRestorePersistedScope();

    // Only if there are at least TWO accepted estates
    if (_hasAtLeastTwoAcceptedEstates()) {
      await _ensureOwnerPinsFlow(); // owner must set AllPin first (if missing)
      await _maybePromptPerEstatePinsIfMissing(); // if some estate pins not set, nudge to fill
      _maybePromptScope(); // then let them pick a scope if none was restored
    }

    await _checkIncompleteEstates();
  }

  Future<void> _initializePermissions() async {
    PermissionStatus locationStatus = await Permission.location.status;
    if (locationStatus.isDenied || locationStatus.isRestricted) {
      locationStatus = await Permission.location.request();
    }
    if (locationStatus.isPermanentlyDenied) {
      _showPermissionDialog(
        getTranslated(context, "Location Permission Required"),
        getTranslated(context,
            "Please enable location permission in settings to use the map features."),
      );
    }

    PermissionStatus notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isRestricted) {
      notificationStatus = await Permission.notification.request();
    }
    if (notificationStatus.isPermanentlyDenied) {
      _showPermissionDialog(
        getTranslated(context, "Notification Permission Required"),
        getTranslated(
            context, "Please enable notification permission in settings."),
      );
    }
  }

  void _showPermissionDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserFirstName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userRef = FirebaseDatabase.instance.ref("App/User/$userId");
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        setState(() {
          firstName = snapshot.child('FirstName').value?.toString() ?? '';
        });
      }
    }
  }

  Future<void> _fetchEstates() async {
    setState(() => isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await estateServices.fetchEstates();
      final parsedEstates = _parseEstates(data)
          .where((estate) => estate['IDUser'] == userId)
          .toList();

      await Future.wait(parsedEstates.map((estate) async {
        await _fetchRatings(estate);
      }));

      estates = parsedEstates;
      isLoading = false;

      // IMPORTANT: recompute visible list based on current scope
      _prepareEstateOptions(); // also locale-aware
      _refreshFilteredEstates();
      if (mounted) setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching estates: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRatings(Map<String, dynamic> estate) async {
    final ratings =
        await customerRateServices.fetchEstateRatingWithUsers(estate['id']);
    final totalRating = ratings.isNotEmpty
        ? ratings.map((e) => e['rating'] as double).reduce((a, b) => a + b) /
            ratings.length
        : 0.0;

    estate['rating'] = totalRating;
    estate['ratingsList'] = ratings;
  }

  void _fetchUserTypeAccount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userRef =
          FirebaseDatabase.instance.ref("App/User/$userId/TypeAccount");

      userRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            typeAccount = event.snapshot.value.toString();
          });
        }
      });
    }
  }

  List<Map<String, dynamic>> _parseEstates(Map<String, dynamic> data) {
    final estateList = <Map<String, dynamic>>[];
    data.forEach((type, estatesByType) {
      estatesByType.forEach((estateID, estateData) {
        // Only include accepted estates ("2")
        if (estateData['IsAccepted'] == "2") {
          estateList.add({
            'id': estateID,
            'nameEn': estateData['NameEn'] ?? 'Unknown',
            'typeAccount': estateData['TypeAccount'] ?? 'Unknown',
            'nameAr': estateData['NameAr'] ?? 'غير معروف',
            'rating': 0.0,
            'fee': estateData['Fee'] ?? 'Free',
            'time': estateData['Time'] ?? '20 min',
            'TypeofRestaurant':
                estateData['TypeofRestaurant'] ?? 'Unknown Type',
            'BioEn': estateData['BioEn'] ?? "Unknown Bio",
            'BioAr': estateData['BioAr'] ?? "Unknown Bio",
            'Sessions': estateData['Sessions'] ?? 'Unknown Session Type',
            'MenuLink': estateData['MenuLink'] ?? 'No Menu',
            'Entry': estateData['Entry'] ?? 'Empty',
            'Lstmusic': estateData['Lstmusic'] ?? 'No music',
            'Type': estateData['Type'] ?? "No type",
            'IDUser': estateData['IDUser'],
            'IsAccepted': estateData['IsAccepted'] ?? '0',
            'Lat': estateData['Lat'] ?? 0,
            'Lon': estateData['Lon'] ?? 0,
            'HasKidsArea': estateData['HasKidsArea'] ?? 'No Kids Allowed',
            'HasValet': estateData['HasValet'] ?? "No valet",
            'ValetWithFees': estateData['ValetWithFees'] ?? "No fees",
            'HasBarber': estateData['HasBarber'] ?? "No Barber",
            'HasMassage': estateData['HasMassage'] ?? "No massage",
            'HasSwimmingPool':
                estateData['HasSwimmingPool'] ?? "No Swimming Pool",
            'HasGym': estateData['HasGym'] ?? "No Gym",
            'IsSmokingAllowed':
                estateData['IsSmokingAllowed'] ?? "Smoking is not allowed",
            'HasJacuzziInRoom': estateData['HasJacuzziInRoom'] ?? "No Jacuzzi",
            'IsCompleted': estateData['IsCompleted'] ?? "0",
          });
        }
      });
    });
    return estateList;
  }

  // ---------- AccessPins load ----------
  Future<void> _loadPins() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseDatabase.instance.ref('App/AccessPins/$uid');
    final snap = await ref.get();

    String? allPin;
    final per = <String, String>{};

    if (snap.exists && snap.value is Map) {
      final m = Map<Object?, Object?>.from(snap.value as Map);
      final ap = m['AllPin'];
      if (ap != null && ap.toString().trim().isNotEmpty) {
        allPin = ap.toString().trim();
      }
      if (m['Estates'] is Map) {
        final e = Map<Object?, Object?>.from(m['Estates'] as Map);
        e.forEach((k, v) {
          if (k != null && v != null && v.toString().trim().isNotEmpty) {
            per[k.toString()] = v.toString().trim();
          }
        });
      }
    }

    setState(() {
      _allPin = allPin;
      _estatePins = per;
      _pinsLoaded = true;
    });
  }

  // Locale-aware estate name by id (for chip restoration, etc.)
  String _localizedEstateNameById(String estateId) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final e = estates.cast<Map<String, dynamic>>().firstWhere(
          (x) => x['id'] == estateId,
          orElse: () => const {},
        );
    if (e.isEmpty) return estateId;
    if (isArabic) {
      final ar = (e['nameAr'] ?? '').toString().trim();
      if (ar.isNotEmpty) return ar;
      final en = (e['nameEn'] ?? '').toString().trim();
      return en.isNotEmpty ? en : estateId;
    } else {
      final en = (e['nameEn'] ?? '').toString().trim();
      if (en.isNotEmpty) return en;
      final ar = (e['nameAr'] ?? '').toString().trim();
      return ar.isNotEmpty ? ar : estateId;
    }
  }

  void _prepareEstateOptions() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final opts = estates
        .map((e) => _EstateOption(
              estateId: e['id'],
              display: isArabic
                  ? ((e['nameAr']?.toString().trim().isNotEmpty ?? false)
                      ? e['nameAr']
                      : (e['nameEn'] ?? e['id']))
                  : ((e['nameEn']?.toString().trim().isNotEmpty ?? false)
                      ? e['nameEn']
                      : (e['nameAr'] ?? e['id'])),
            ))
        .toList()
      ..sort(
          (a, b) => a.display.toLowerCase().compareTo(b.display.toLowerCase()));

    setState(() {
      _estateOptions = opts;
      _scopeEstateName ??= getTranslated(context, "Choose control scope");
    });
  }

  bool _hasAtLeastTwoAcceptedEstates() => _estateOptions.length >= 2;

  // ---------- enforce “owner sets AllPin first if has ≥2 estates” ----------
  Future<void> _ensureOwnerPinsFlow() async {
    if (_ownerFlowHandledOnce) return;
    _ownerFlowHandledOnce = true;

    if (!_hasAtLeastTwoAcceptedEstates()) return; // gate

    if ((_allPin == null || _allPin!.isEmpty)) {
      final newPin = await _showOwnerSetupDialog(context);
      if (newPin == null || newPin.trim().isEmpty) return;
      await _saveAllPin(newPin.trim());
      setState(() => _allPin = newPin.trim());

      // Immediately invite to add per-estate pins
      await _showPerEstatePinsDialog(context);
      await _loadPins(); // refresh cache
    }
  }

  Future<void> _maybePromptPerEstatePinsIfMissing() async {
    if (!_hasAtLeastTwoAcceptedEstates()) return;
    if ((_allPin ?? '').isEmpty) return; // owner not set yet
    if (_askedPerEstatePinsThisSession) return;

    // If any accepted estate is missing a pin -> prompt
    final missing = _estateOptions
        .where((e) => !_estatePins.containsKey(e.estateId))
        .toList();

    if (missing.isNotEmpty) {
      _askedPerEstatePinsThisSession = true;
      await _showPerEstatePinsDialog(context);
      await _loadPins();
    }
  }

  Future<void> _saveAllPin(String pin) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseDatabase.instance
        .ref('App/AccessPins/$uid')
        .update({'AllPin': pin});
  }

  Future<void> _saveEstatePins(Map<String, String> pins) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || pins.isEmpty) return;
    await FirebaseDatabase.instance
        .ref('App/AccessPins/$uid/Estates')
        .update(pins);
  }

  // ---------- Persisted scope (per user) ----------
  static const _kScopeUidKey = 'scope.uid';
  static const _kScopeIsAllKey = 'scope.isAll';
  static const _kScopeEstateIdKey = 'scope.estateId';
  static const _kScopeEstateNameKey = 'scope.estateName';

  Future<void> _persistScopeSelection({
    required bool isAll,
    String? estateId,
    String? estateName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await prefs.setString(_kScopeUidKey, uid);
    await prefs.setBool(_kScopeIsAllKey, isAll);
    if (isAll) {
      await prefs.remove(_kScopeEstateIdKey);
      await prefs.setString(_kScopeEstateNameKey,
          getTranslated(context, "-- All estates --") ?? "-- All estates --");
    } else {
      if (estateId != null) {
        await prefs.setString(_kScopeEstateIdKey, estateId);
      }
      await prefs.setString(_kScopeEstateNameKey,
          estateName ?? _localizedEstateNameById(estateId ?? ''));
    }
  }

  Future<void> _clearPersistedScope() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kScopeUidKey);
    await prefs.remove(_kScopeIsAllKey);
    await prefs.remove(_kScopeEstateIdKey);
    await prefs.remove(_kScopeEstateNameKey);
  }

  Future<void> _maybeRestorePersistedScope() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final savedUid = prefs.getString(_kScopeUidKey);
    if (savedUid != uid) return; // different user -> ignore

    final isAll = prefs.getBool(_kScopeIsAllKey) ?? false;
    final savedId = prefs.getString(_kScopeEstateIdKey);

    // “All” scope
    if (isAll) {
      if ((_allPin?.isNotEmpty ?? false) && _hasAtLeastTwoAcceptedEstates()) {
        _scopeAll = true;
        _scopeEstateId = null;
        _scopeEstateName = getTranslated(context, "-- All estates --");
        _refreshFilteredEstates();
        _scopePromptShown = true; // don't prompt again
        if (mounted) setState(() {});
        await _updateThisDeviceTokenScope(isAll: true);
      } else {
        await _clearPersistedScope();
      }
      return;
    }

    // Single estate scope
    if (savedId != null &&
        _estateOptions.any((e) => e.estateId == savedId) &&
        _hasAtLeastTwoAcceptedEstates()) {
      _scopeAll = false;
      _scopeEstateId = savedId;
      final found = _estateOptions.firstWhere(
        (e) => e.estateId == savedId,
        orElse: () => _EstateOption(
          estateId: savedId,
          display: _localizedEstateNameById(savedId),
        ),
      );
      _scopeEstateName = found.display;
      _refreshFilteredEstates();
      _scopePromptShown = true; // don't prompt again
      if (mounted) setState(() {});
      await _updateThisDeviceTokenScope(isAll: false, estateId: savedId);
    } else {
      await _clearPersistedScope();
    }
  }

  // ---------- scope prompt ----------
  bool _shouldOfferScope() {
    if (!_pinsLoaded) return false;
    if (!_hasAtLeastTwoAcceptedEstates()) return false;
    // If scope already chosen (either restored or set), don't prompt again
    if (_scopeAll || _scopeEstateId != null) return false;
    return ((_allPin?.isNotEmpty ?? false) || _estatePins.isNotEmpty);
  }

  void _maybePromptScope() {
    if (_scopePromptShown) return;
    if (!_shouldOfferScope()) return;

    _scopePromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openScopePicker());
  }

  Future<void> _openScopePicker() async {
    final res = await showDialog<_PickedScopeResult>(
      context: context,
      barrierDismissible: false, // cannot tap outside to dismiss
      builder: (_) => _ScopePickerDialog(
        estates: _estateOptions,
        allEnabled: _allPin != null && _allPin!.isNotEmpty,
        allPin: _allPin,
        estatePins: _estatePins,
      ),
    );

    if (res == null) {
      // Should never happen (dialog is non-dismissable & back is blocked)
      return;
    }

    if (res.isAll) {
      _scopeAll = true;
      _scopeEstateId = null;
      _scopeEstateName = getTranslated(context, "-- All estates --");
      await _persistScopeSelection(
        isAll: true,
        estateName: _scopeEstateName,
      );
      await _updateThisDeviceTokenScope(isAll: true);
    } else {
      final found = _estateOptions.firstWhere(
        (e) => e.estateId == res.estateId,
        orElse: () => _EstateOption(
          estateId: res.estateId!,
          display: _localizedEstateNameById(res.estateId!),
        ),
      );
      _scopeAll = false;
      _scopeEstateId = res.estateId;
      _scopeEstateName = found.display;
      await _persistScopeSelection(
        isAll: false,
        estateId: _scopeEstateId,
        estateName: _scopeEstateName,
      );
      await _updateThisDeviceTokenScope(isAll: false, estateId: _scopeEstateId);
    }

    _refreshFilteredEstates(); // <<< enforce scope immediately
    if (mounted) setState(() {});
  }

  // ---------- dialogs ----------
  Future<String?> _showOwnerSetupDialog(BuildContext context) async {
    final t = (String k) => getTranslated(context, k);
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false, // block Android back
        child: AlertDialog(
          title: Text(t("You're the owner")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t(
                  "Create an All estates PIN. Share it only with trusted owners/admins. For managers, add per-estate PINs under Access PINs later.")),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t("All estates PIN"),
                  hintText: t("Enter a PIN (e.g. 1234)"),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t("Cancel"))),
            ElevatedButton(
              onPressed: () {
                final pin = ctrl.text.trim();
                if (pin.isEmpty) return;
                Navigator.pop(context, pin);
              },
              child: Text(t("Save")),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPerEstatePinsDialog(BuildContext context) async {
    final t = (String k) => getTranslated(context, k);

    final controllers = <String, TextEditingController>{
      for (final e in _estateOptions)
        e.estateId: TextEditingController(text: _estatePins[e.estateId] ?? "")
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false, // block Android back
        child: StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: Text(t("Choose control scope")),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          t("Switch the estate you manage"),
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    ..._estateOptions.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: controllers[e.estateId],
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "${e.display}  (${t("PIN")})",
                              hintText: t("Enter the PIN"),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(t("Skip"))),
              ElevatedButton(
                onPressed: () async {
                  final updates = <String, String>{};
                  controllers.forEach((estateId, c) {
                    final v = c.text.trim();
                    if (v.isNotEmpty) updates[estateId] = v;
                  });
                  if (updates.isNotEmpty) {
                    await _saveEstatePins(updates);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(t("Save")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- SCOPE-AWARE FILTERING ----------
  List<Map<String, dynamic>> _getScopedEstates() {
    if (_scopeAll || _scopeEstateId == null) return estates;
    return estates.where((e) => e['id'] == _scopeEstateId).toList();
  }

  void _refreshFilteredEstates() {
    final base = _getScopedEstates();
    final q = searchController.text.toLowerCase().trim();

    final results = q.isEmpty
        ? base
        : base.where((estate) {
            final nameEn = (estate['nameEn'] ?? '').toString().toLowerCase();
            final nameAr = (estate['nameAr'] ?? '').toString().toLowerCase();
            return nameEn.contains(q) || nameAr.contains(q);
          }).toList();

    setState(() {
      searchActive = q.isNotEmpty;
      filteredEstates = results;
    });
  }

  void _filterEstates() {
    _refreshFilteredEstates();
  }

  void _clearSearch() {
    searchController.clear();
    FocusScope.of(context).unfocus();
    _refreshFilteredEstates();
  }

  String _getGreeting() {
    final currentHour = DateTime.now().hour;
    if (currentHour < 12) {
      return getTranslated(context, "Good Morning");
    } else if (currentHour < 18) {
      return getTranslated(context, "Good Afternoon");
    } else {
      return getTranslated(context, "Good Evening");
    }
  }

  Future<void> _checkIncompleteEstates() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final DatabaseReference estatesRef =
        FirebaseDatabase.instance.ref("App").child("Estate");
    DataSnapshot snapshot = await estatesRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> estatesData =
          snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> incompleteEstates = [];

      estatesData.forEach((type, estatesByType) {
        estatesByType.forEach((estateID, estateData) {
          if (estateData['IDUser'] == userId &&
              estateData['IsCompleted'] == "0") {
            incompleteEstates.add({
              'id': estateID,
              'type': type,
              'nameEn': estateData['NameEn'] ?? 'Unknown',
              'nameAr': estateData['NameAr'] ?? 'غير معروف',
            });
          }
        });
      });

      if (incompleteEstates.isNotEmpty &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIncompleteEstateDialog(incompleteEstates);
        });
      }
    }
  }

  void _showIncompleteEstateDialog(
      List<Map<String, dynamic>> incompleteEstates) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Incomplete Estates")),
          content: Text(getTranslated(context,
              "You have incomplete estates. Do you want to continue adding them?")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final firstEstate = incompleteEstates.first;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MapsScreen(
                      id: firstEstate['id'],
                      typeEstate: firstEstate['type'],
                    ),
                  ),
                );
              },
              child: Text(getTranslated(context, "OK")),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(getTranslated(context, "Cancel")),
            ),
          ],
        );
      },
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      final base = _getScopedEstates();
      if (category == "All") {
        filteredEstates = base;
      } else {
        filteredEstates = base
            .where((estate) =>
                estate['Type']?.toLowerCase() == category.toLowerCase())
            .toList();
      }
    });
  }

  // ---------- NEW: mirror current scope into THIS device's token ----------
  Future<void> _updateThisDeviceTokenScope({
    required bool isAll,
    String? estateId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final scope = <String, dynamic>{
      'type': isAll ? 'all' : 'estate',
      if (!isAll && estateId != null) 'estateId': estateId,
      'updatedAt': ServerValue.timestamp,
    };

    final ref =
        FirebaseDatabase.instance.ref('App/User/$uid/Tokens/$token/scope');
    await ref.set(scope);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
      // NEW: Floating chat button -> navigates to ChatBotScreen
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatBotScreen()),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(getTranslated(context, "Chat Bot")),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: ShimmerEstateCard())
          : estates.isEmpty
              ? Center(
                  child: Text(
                    getTranslated(
                        context, "You have not added any estates yet."),
                    style: kSecondaryStyle,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchEstates();
                    await _loadPins();
                    _prepareEstateOptions();
                    // keep/restore scope if persisted
                    await _maybeRestorePersistedScope();
                    if (_hasAtLeastTwoAcceptedEstates()) {
                      await _maybePromptPerEstatePinsIfMissing();
                    }
                    _refreshFilteredEstates(); // keep scope honored on refresh
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting + (optional) scope
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "${_getGreeting()}, ",
                                    style: const TextStyle(
                                      color: kEstatesTextsColor,
                                      fontSize: 22,
                                    ),
                                  ),
                                  Text(
                                    firstName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if ((_allPin?.isNotEmpty ?? false) ||
                                  _estatePins.isNotEmpty)
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        _scopeAll
                                            ? getTranslated(
                                                context, "-- All estates --")
                                            : (_scopeEstateName ??
                                                getTranslated(context,
                                                    "Choose control scope")),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _openScopePicker,
                                      child: Text(getTranslated(
                                          context, "Change scope")),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // Search
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SearchTextField(
                            controller: searchController,
                            onClear: _clearSearch,
                            onChanged: (value) => _filterEstates(),
                          ),
                        ),

                        15.kH,

                        // Section title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            searchActive
                                ? getTranslated(context, "Search Results")
                                : getTranslated(context, "My Estates"),
                            style: const TextStyle(
                              color: kEstatesTextsColor,
                              fontSize: 22,
                            ),
                          ),
                        ),

                        // Estate list (SCOPE-ENFORCED)
                        filteredEstates.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    getTranslated(context, "No results found"),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: filteredEstates.length,
                                itemBuilder: (context, index) {
                                  final estate = filteredEstates[index];
                                  return GestureDetector(
                                    onTap: () =>
                                        _navigateToEstateProfile(estate),
                                    child: EstateCard(
                                      nameEn: estate['nameEn'],
                                      estateId: estate['id'],
                                      nameAr: estate['nameAr'],
                                      rating: estate['rating'],
                                      typeAccount: typeAccount,
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _navigateToEstateProfile(Map<String, dynamic> estate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEstateScreen(
          nameEn: estate['nameEn'],
          nameAr: estate['nameAr'],
          estateId: estate['id'],
          estateType: estate['Type'],
          location: "Rose Garden",
          rating: estate['rating'],
          fee: estate['fee'],
          deliveryTime: estate['time'],
          price: 32.0,
          typeOfRestaurant: estate['TypeofRestaurant'],
          bioEn: estate['BioEn'],
          bioAr: estate['BioAr'],
          sessions: estate['Sessions'],
          menuLink: estate['MenuLink'],
          entry: estate['Entry'],
          music: estate['Lstmusic'],
          lat: estate['Lat'] ?? 0,
          lon: estate['Lon'] ?? 0,
          type: estate['Type'],
          isSmokingAllowed: estate['IsSmokingAllowed'] ?? "",
          hasGym: estate['HasGym'] ?? "",
          hasMassage: estate['HasMassage'] ?? '',
          hasBarber: estate['HasBarber'] ?? '',
          hasSwimmingPool: estate['HasSwimmingPool'] ?? '',
          hasKidsArea: estate['HasKidsArea'] ?? '',
          hasJacuzziInRoom: estate['HasJacuzziInRoom'] ?? '',
          valetWithFees: estate['ValetWithFees'] ?? '',
          hasValet: estate['HasValet'] ?? '',
          lstMusic: estate['Lstmusic'] ?? '',
        ),
      ),
    );
  }
}

// ---------- Scope picker dialog ----------
class _ScopePickerDialog extends StatefulWidget {
  const _ScopePickerDialog({
    required this.estates,
    required this.allEnabled,
    required this.allPin,
    required this.estatePins,
  });

  final List<_EstateOption> estates; // contains { estateId, display }
  final bool allEnabled; // whether "-- All estates --" option is available
  final String? allPin; // stored All estates PIN
  final Map<String, String> estatePins; // { estateId : pin }

  @override
  State<_ScopePickerDialog> createState() => _ScopePickerDialogState();
}

class _ScopePickerDialogState extends State<_ScopePickerDialog> {
  String? _selected;
  String? _error;
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear error as user types to improve UX
    _pinCtrl.addListener(() {
      if (_error != null && mounted) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always read translations at build-time so language switches reflect immediately
    String t(String k) => getTranslated(context, k);

    // Compute localized label for the "All" option at build-time so it updates with locale
    final String allEstatesLabel = t("-- All estates --");

    return WillPopScope(
      onWillPop: () async => false, // BLOCK Android back entirely
      child: AlertDialog(
        title: Text(t("Choose control scope")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selected,
              decoration: InputDecoration(
                labelText: t("Estate"),
                border: const OutlineInputBorder(),
              ),
              items: [
                if (widget.allEnabled)
                  DropdownMenuItem(
                    value: 'ALL',
                    child: Text(allEstatesLabel),
                  ),
                ...widget.estates.map(
                  (e) => DropdownMenuItem(
                    value: e.estateId,
                    // `e.display` is a proper name pulled from DB; we don't auto-translate it.
                    // It will render as-is, while the UI chrome (labels) are localized.
                    child: Text(e.display),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _selected = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t("PIN"),
                hintText: t("Enter the PIN"),
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Keep this message localized each build
              t("Ask the owner for this estate's PIN (or the “All estates” PIN for owners)."),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          // NOTE: No Cancel button (as requested)
          ElevatedButton(
            onPressed: () {
              final sel = _selected;
              final pin = _pinCtrl.text.trim();

              if (sel == null || pin.isEmpty) {
                setState(() => _error = t("Required"));
                return;
              }

              if (sel == 'ALL') {
                if (widget.allPin != null && pin == widget.allPin) {
                  Navigator.pop<_PickedScopeResult>(
                    context,
                    _PickedScopeResult.all(),
                  );
                } else {
                  setState(() => _error = t("Incorrect PIN"));
                }
              } else {
                final expected = widget.estatePins[sel];
                if (expected != null && pin == expected) {
                  Navigator.pop<_PickedScopeResult>(
                    context,
                    _PickedScopeResult.estate(sel),
                  );
                } else {
                  setState(() => _error = t("Incorrect PIN"));
                }
              }
            },
            child: Text(t("Enter")),
          ),
        ],
      ),
    );
  }
}
