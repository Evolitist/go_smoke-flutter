import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'pages/home.dart';
import 'pages/profile.dart';
import 'pages/settings.dart';
import 'services/auth.dart';
import 'services/fcm.dart';
import 'services/prefs.dart';

void main() async {
  await Prefs.build();
  runApp(AuthManager(
    child: App(),
  ));
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final Prefs _prefs = Prefs();
  final FCM _fcm = FCM();
  Brightness _brightness;

  @override
  void initState() {
    super.initState();
    _prefs<bool>(
      'isDark',
      (value) {
        setState(() {
          _brightness = value ? Brightness.dark : Brightness.light;
        });
      },
      defaultValue: false,
    );
    WidgetsBinding.instance.addObserver(this);
    _fcm.init((s) => print(s));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retrieveDynamicLink();
    }
  }

  Future<void> _retrieveDynamicLink() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.retrieveDynamicLink();
    AuthManager.of(context).joinGroup(data?.link);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          brightness: _brightness,
          primaryColor: Colors.grey[900],
          toggleableActiveColor: Colors.orangeAccent[200],
          accentColor: Colors.orangeAccent[400],
          buttonTheme: ButtonThemeData(
            minWidth: 40.0,
            height: 40.0,
          ),
        ),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (ctx) => HomePage());
            case '/settings':
              return CupertinoPageRoute(builder: (ctx) => SettingsPage());
            case '/profile':
              return CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (ctx) => ProfilePage(),
              );
          }
        },
    );
  }
}
