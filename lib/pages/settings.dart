import 'package:flutter/material.dart';
import '../services/prefs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  final Prefs _prefs = Prefs();
  bool isDark;

  @override
  void initState() {
    super.initState();
    isDark = _prefs['isDark'] ?? false;
  }

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return SwitchListTile(
          title: const Text("Dark theme"),
          value: isDark,
          onChanged: (value) {
            _prefs['isDark'] = value;
            setState(() {
              isDark = value;
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
        title: Text('Settings'),
      ),
      body: ListView.builder(itemBuilder: _buildListItem),
    );
  }
}