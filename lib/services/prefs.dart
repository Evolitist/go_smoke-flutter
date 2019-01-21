import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager extends StatefulWidget {
  PrefsManager({
    Key key,
    @required this.prefs,
    this.child,
  })  : assert(prefs != null),
        super(key: key);

  final Widget child;
  final SharedPreferences prefs;

  @override
  State<StatefulWidget> createState() => PrefsManagerState();

  static PrefsManagerState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(PrefsModel) as PrefsModel)
        .controller;
  }
}

class PrefsManagerState extends State<PrefsManager> {
  Map<String, dynamic> values = {};

  Future set(String key, dynamic value, [bool refresh = true]) async {
    Future job;
    if (value is bool) {
      job = widget.prefs.setBool(key, value);
    } else if (value is int) {
      job = widget.prefs.setInt(key, value);
    } else if (value is double) {
      job = widget.prefs.setDouble(key, value);
    } else if (value is String) {
      job = widget.prefs.setString(key, value);
    } else if (value is List<String>) {
      job = widget.prefs.setStringList(key, value);
    } else if (value == null) {
      job = widget.prefs.remove(key);
    }
    if (job == null) {
      throw Exception('Unsupported preference type ${value.runtimeType}');
    } else {
      if (refresh) {
        setState(() {
          values[key] = value;
        });
      } else {
        values[key] = value;
      }
      return job;
    }
  }

  T _get<T>(String key) => widget.prefs.get(key);

  @override
  void initState() {
    super.initState();
    widget.prefs.getKeys().forEach((s) {
      values[s] = widget.prefs.get(s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrefsModel(
      controller: this,
      prefs: Map.of(values),
      child: widget.child,
    );
  }
}

class PrefsModel extends InheritedModel<String> {
  const PrefsModel({
    Key key,
    @required this.controller,
    @required this.prefs,
    Widget child,
  }) : super(key: key, child: child);

  @protected
  final PrefsManagerState controller;

  @protected
  final Map<String, dynamic> prefs;

  Future set(String key, dynamic value) => controller.set(key, value);

  T get<T>(String key, [T defaultValue]) =>
      prefs[key] ?? controller._get(key) ?? defaultValue;

  @override
  bool isSupportedAspect(Object aspect) {
    return prefs.containsKey(aspect);
  }

  @override
  bool updateShouldNotify(PrefsModel old) => true;

  @override
  bool updateShouldNotifyDependent(PrefsModel old, Set<String> deps) {
    for (var s in deps) {
      if (prefs.containsKey(s) && prefs[s] != old.prefs[s]) {
        return true;
      }
    }
    return false;
  }

  static dynamic of(BuildContext context, {String aspect, dynamic defaultValue}) {
    PrefsModel model = InheritedModel.inheritFrom(context, aspect: aspect);
    if (aspect == null) return model;
    return model.get(aspect, defaultValue);
  }
}
