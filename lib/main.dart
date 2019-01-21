import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home.dart';
import 'pages/profile.dart';
import 'pages/settings.dart';
import 'services/auth.dart';
import 'services/prefs.dart';

void main() async {
  runApp(PrefsManager(
    prefs: await SharedPreferences.getInstance(),
    child: AuthManager(
      child: App(),
    ),
  ));
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retrieveDynamicLink();
    }
  }

  Future<void> _retrieveDynamicLink() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.retrieveDynamicLink();
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
        brightness: PrefsModel.of(context, aspect: 'isDark', defaultValue: false) ? Brightness.dark : Brightness.light,
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
