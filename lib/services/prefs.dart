import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static final Prefs _singleton = Prefs._();
  final Map<String, ValueNotifier<dynamic>> _notifiers = Map();
  final Map<String, List<VoidCallback>> _callbacks = Map();
  SharedPreferences _prefs;

  Prefs._();

  factory Prefs() {
    if (_singleton._prefs == null) {
      throw Exception('You must call build() before using constructor');
    }
    return _singleton;
  }

  static Future<Prefs> build() async {
    _singleton._prefs ??= await SharedPreferences.getInstance();
    return _singleton;
  }

  void _checkListener<T>(String key, T value) {
    if (!_notifiers.containsKey(key)) {
      _notifiers[key] = ValueNotifier(value);
      _callbacks[key] = List()..length = 1;
    }
  }

  T get<T>(String key, {T defaultValue}) {
    _checkListener<T>(key, defaultValue);
    return _notifiers[key].value;
  }

  dynamic operator [](String key) => get(key);

  void set<T>(String key, T value) {
    _checkListener<T>(key, value);
    _set(key, value);
    _notifiers[key].value = value;
  }

  void operator []=(String key, dynamic value) => set(key, value);

  void listen<T>(String key, ValueChanged<T> listener,
      {int uid: 0, T defaultValue}) {
    dynamic _defValue = _prefs.get(key);
    dynamic defValue = _defValue is List ? _defValue.cast<String>() : _defValue;
    _checkListener<T>(key, defValue ?? defaultValue);
    if (_callbacks[key][uid] != null) {
      _notifiers[key].removeListener(_callbacks[key][uid]);
    }
    _callbacks[key][uid] = () => listener(_prefs.get(key));
    _notifiers[key].addListener(_callbacks[key][uid]);
    listener(_notifiers[key].value);
  }

  void stop(String key, [int uid = 0]) {
    if (_notifiers.containsKey(key) && _callbacks[key][uid] != null) {
      _notifiers[key].removeListener(_callbacks[key][uid]);
    }
  }

  call<T>(String key, ValueChanged<T> listener, {int uid: 0, T defaultValue}) =>
      listen(key, listener, uid: uid, defaultValue: defaultValue);

  void _set(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else if (value != null) {
      throw Exception('Unsupported preference type ${value.runtimeType}');
    }
  }
}
