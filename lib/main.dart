import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home.dart';
import 'pages/profile.dart';
import 'services/auth.dart';
import 'services/prefs.dart';

void main() async {
  runApp(PrefsManager(
    prefs: await SharedPreferences.getInstance(),
    child: const AuthManager(
      child: App(),
    ),
  ));
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

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
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
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
        buttonTheme: ButtonThemeData(minWidth: 40, height: 40),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        toggleableActiveColor: Colors.orangeAccent[200],
        accentColor: Colors.orangeAccent[400],
        buttonTheme: ButtonThemeData(minWidth: 40, height: 40),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (ctx) => const HomePage());
          case '/profile':
            return CupertinoPageRoute(
              fullscreenDialog: true,
              builder: (ctx) => ProfilePage(),
            );
        }
        return MaterialPageRoute(builder: (ctx) => const SizedBox());
      },
    );
  }
}
