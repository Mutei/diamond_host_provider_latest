import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// What the user is currently allowed to control in the app session.
class AccessScope {
  final String type; // 'all' or 'estate'
  final String? estateId; // null if 'all'

  const AccessScope._(this.type, this.estateId);

  static const none = AccessScope._('none', null);

  factory AccessScope.all() => const AccessScope._('all', null);
  factory AccessScope.estate(String id) => AccessScope._('estate', id);

  Map<String, dynamic> toJson() => {'type': type, 'estateId': estateId};
  static AccessScope fromJson(Map<String, dynamic> m) =>
      AccessScope._(m['type'] as String, m['estateId'] as String?);
}

/// Simple local store for AccessScope.
/// (We also mirror it to Realtime DB under App/User/{uid}/CurrentScope for visibility.)
class AccessScopeStore {
  static const _kKey = 'dhp_access_scope_v1';

  static Future<void> save(AccessScope scope) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, jsonEncode(scope.toJson()));
  }

  static Future<AccessScope> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    if (raw == null) return AccessScope.none;
    try {
      return AccessScope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AccessScope.none;
    }
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kKey);
  }
}
