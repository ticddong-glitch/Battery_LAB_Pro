import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_preferences.dart';
import 'db_helper.dart';

class PreferencesRepository {
  PreferencesRepository._();
  static final PreferencesRepository instance = PreferencesRepository._();

  static const String _prefsKey = 'app_preferences';
  final ValueNotifier<AppPreferences> preferencesNotifier =
      ValueNotifier<AppPreferences>(AppPreferences.defaults());

  bool _initialized = false;

  AppPreferences get current => preferencesNotifier.value;

  Future<void> init() async {
    if (_initialized) return;
    final raw = await DBHelper.instance.getPreference(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      await save(AppPreferences.defaults());
      _initialized = true;
      return;
    }

    final map = (jsonDecode(raw) as Map).cast<String, Object?>();
    preferencesNotifier.value = AppPreferences.fromMap(map);
    _initialized = true;
  }

  Future<void> save(AppPreferences prefs) async {
    preferencesNotifier.value = prefs;
    final text = jsonEncode(prefs.toMap());
    await DBHelper.instance.setPreference(_prefsKey, text);
  }
}
