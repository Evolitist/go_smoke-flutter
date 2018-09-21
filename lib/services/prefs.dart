import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static final Prefs _singleton = Prefs._();
  final Map<String, ValueNotifier<dynamic>> _listeners = Map();
  final Map<String, List<VoidCallback>> _events = Map();
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
    if (!_listeners.containsKey(key)) {
      _listeners[key] = ValueNotifier(value);
      _events[key] = List()..length = 1;
      _set(key, value);
    }
  }

  T get<T>(String key, {T defaultValue}) {
    _checkListener<T>(key, defaultValue);
    return _listeners[key].value;
  }

  dynamic operator [](String key) => get(key);

  void set<T>(String key, T value) {
    _checkListener<T>(key, value);
    _set(key, value);
    _listeners[key].value = value;
  }

  void operator []=(String key, dynamic value) => set(key, value);

  void listen<T>(String key, ValueChanged<T> listener, {int uid: 0, T defaultValue}) {
    _checkListener<T>(key, defaultValue);
    if (_events[key][uid] != null) {
      _listeners[key].removeListener(_events[key][uid]);
    }
    _events[key][uid] = () => listener(_prefs.get(key));
    _listeners[key].addListener(_events[key][uid]);
    listener(_listeners[key].value);
  }

  void stop(String key, [int uid = 0]) {
    if (_listeners.containsKey(key) && _events[key][uid] != null) {
      _listeners[key].removeListener(_events[key][uid]);
    }
  }

  call<T>(String key, ValueChanged<T> listener, {int uid: 0, T defaultValue}) => listen(key, listener, uid: uid, defaultValue: defaultValue);

  void _set(String key, dynamic value) async {
    if (value is bool) {
      _prefs.setBool(key, value);
    } else if (value is int) {
      _prefs.setInt(key, value);
    } else if (value is double) {
      _prefs.setDouble(key, value);
    } else if (value is String) {
      _prefs.setString(key, value);
    } else if (value is List<String>) {
      _prefs.setStringList(key, value);
    } else if (value != null) {
      throw Exception('Unsupported preference type ${value.runtimeType}');
    }
  }
}
