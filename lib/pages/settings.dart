import 'package:flutter/material.dart';
import 'package:go_smoke/services/prefs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  final Prefs _prefs = Prefs();
  bool isDark;
  bool dockFab;

  @override
  void initState() {
    super.initState();
    isDark = _prefs.getBool("isDark");
    dockFab = _prefs.getBool("docked");
  }

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return SwitchListTile(
          title: const Text("Dark theme"),
          value: isDark,
          onChanged: (value) {
            _prefs.setBool("isDark", value);
            setState(() {
              isDark = value;
            });
          },
        );
      case 1:
        return SwitchListTile(
          title: const Text("Dock FAB"),
          value: dockFab,
          onChanged: (value) {
            _prefs.setBool("docked", value);
            setState(() {
              dockFab = value;
            });
          },
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView.builder(itemBuilder: _buildListItem),
    );
  }
}