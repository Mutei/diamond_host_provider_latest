// lib/widgets/bottom_navigation_bar.dart
import 'dart:async';

import 'package:daimond_host_provider/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';

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
          icon: const Icon(Icons.home),
          label: getTranslated(context, 'Main Screen'),
        ),
        BottomNavigationBarItem(
          icon: const _NewRequestsBadgeIcon(),
          label: getTranslated(context, "Booking Status"),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.post_add),
          label: getTranslated(context, 'All Posts'),
        ),
      ],
    );
  }
}

enum _ScopeType { none, all, estate }

class _NewRequestsBadgeIcon extends StatefulWidget {
  const _NewRequestsBadgeIcon();

  @override
  State<_NewRequestsBadgeIcon> createState() => _NewRequestsBadgeIconState();
}

class _NewRequestsBadgeIconState extends State<_NewRequestsBadgeIcon> {
  String? _uid;
  String? _token;

  _ScopeType _scopeType = _ScopeType.none;
  String? _estateId; // only when _scopeType == estate
  int _count = 0;

  StreamSubscription<DatabaseEvent>? _bookingsSub;
  StreamSubscription<DatabaseEvent>? _tokenScopeSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _token = await FirebaseMessaging.instance.getToken();
    if (_uid == null) return;

    // initial scope resolve
    await _resolveScope();

    // listen to token-scope changes (if we have a token)
    if (_token != null) {
      final scopeRef =
          FirebaseDatabase.instance.ref('App/User/$_uid/Tokens/$_token/scope');
      _tokenScopeSub = scopeRef.onValue.listen((event) async {
        final changed = await _resolveScope();
        if (changed) _restartBookingsListener();
      });
    }

    _restartBookingsListener();
  }

  /// Returns true if scope changed
  Future<bool> _resolveScope() async {
    final oldType = _scopeType;
    final oldEstate = _estateId;

    final res = await _getEffectiveScope();
    _scopeType = res.$1;
    _estateId = res.$2;

    return oldType != _scopeType || oldEstate != _estateId;
  }

  /// (scopeType, estateId)
  Future<(_ScopeType, String?)> _getEffectiveScope() async {
    try {
      final uid = _uid;
      final token = _token;
      if (uid == null) return (_ScopeType.none, null);

      // 1) token scope
      if (token != null) {
        final snap = await FirebaseDatabase.instance
            .ref('App/User/$uid/Tokens/$token/scope')
            .get();
        final t = snap.child('type').value?.toString();
        if (t == 'all') return (_ScopeType.all, null);
        if (t == 'estate') {
          final e = snap.child('estateId').value?.toString();
          if (e != null && e.isNotEmpty) return (_ScopeType.estate, e);
        }
      }

      // 2) user-wide scope
      final userScopeSnap = await FirebaseDatabase.instance
          .ref('App/User/$uid/CurrentScope')
          .get();
      final ut = userScopeSnap.child('type').value?.toString();
      if (ut == 'all') return (_ScopeType.all, null);
      if (ut == 'estate') {
        final e = userScopeSnap.child('estateId').value?.toString();
        if (e != null && e.isNotEmpty) return (_ScopeType.estate, e);
      }

      // 3) SharedPreferences fallback
      final sp = await SharedPreferences.getInstance();
      final isAll = sp.getBool('scope.isAll') ?? false;
      if (isAll) return (_ScopeType.all, null);
      final savedId = sp.getString('scope.estateId');
      if (savedId != null && savedId.isNotEmpty) {
        return (_ScopeType.estate, savedId);
      }

      return (_ScopeType.none, null);
    } catch (_) {
      return (_ScopeType.none, null);
    }
  }

  void _restartBookingsListener() {
    _bookingsSub?.cancel();

    // If scope none → plain icon, no listener
    if (_uid == null || _scopeType == _ScopeType.none) {
      setState(() => _count = 0);
      return;
    }

    final ref = FirebaseDatabase.instance
        .ref('App/Booking/Book')
        .orderByChild('IDOwner')
        .equalTo(_uid);

    _bookingsSub = ref.onValue.listen((event) {
      int c = 0;
      if (event.snapshot.value is Map) {
        final m = Map<Object?, Object?>.from(event.snapshot.value as Map);
        m.forEach((_, v) {
          if (v is Map) {
            final statusRaw = v['Status'];
            final pending = statusRaw == '1' || statusRaw == 1;
            if (!pending) return;

            // estate filter only when scope == estate
            if (_scopeType == _ScopeType.estate) {
              final eId = v['IDEstate']?.toString();
              if (eId != _estateId) return;
            }
            // scope == all → no estate filter
            c++;
          }
        });
      }
      if (mounted) setState(() => _count = c);
    });
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _tokenScopeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count <= 0) {
      return const Icon(Icons.account_box);
    }
    return badges.Badge(
      badgeContent: Text(
        _count.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      child: const Icon(Icons.account_box),
    );
  }
}
