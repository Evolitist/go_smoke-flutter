import 'package:flutter/material.dart';

import 'services/fcm.dart';
import 'services/prefs.dart';
import 'pages/home.dart';

void main() async {
  await Prefs.build();
  runApp(new App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final Prefs _prefs = Prefs();
  final FCM _fcm = FCM();
  Brightness _brightness;

  @override
  void initState() {
    super.initState();
    _prefs<bool>('isDark', (value) => setState(() {
      _brightness = value ? Brightness.dark : Brightness.light;
    }), false);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = _brightness == Brightness.dark;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: _brightness,
        primaryColor: isDark ? null : Colors.white,
        toggleableActiveColor: Colors.orangeAccent[200],
        accentColor: Colors.orangeAccent[400],
      ),
      home: HomePage(),
    );
  }
}
