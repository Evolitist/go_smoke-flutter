import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  final Map<String, ValueChanged<bool>> _listeners = Map();
  SharedPreferences _prefs;

  Prefs() {
    _init();
  }

  void _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getBool(String key, [bool defaultValue = false]) => _prefs?.getBool(key) ?? defaultValue;

  bool listenBool(String key, ValueChanged<bool> listener, [bool defaultValue = false]) {
    _listeners[key] = listener;
    return _prefs?.getBool(key) ?? defaultValue;
  }

  void setBool(String key, bool value) {
    _prefs?.setBool(key, value);
    if (_listeners[key] != null) _listeners[key](value);
  }
}
