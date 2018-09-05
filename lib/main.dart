import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backdrop.dart';
import 'olc.dart';

void main() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Brightness brightness =
      (prefs.getBool("isDark") ?? false) ? Brightness.dark : Brightness.light;
  runApp(new App(prefs, brightness));
}

class App extends StatefulWidget {
  App(this.prefs, this._brightness);

  final SharedPreferences prefs;
  final Brightness _brightness;

  @override
  _AppState createState() => _AppState(_brightness);
}

class _AppState extends State<App> {
  _AppState(this.brightness);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  Brightness brightness;

  @override
  void initState() {
    super.initState();
    notifications.initialize(InitializationSettings(
      AndroidInitializationSettings('ic_notification'),
      IOSInitializationSettings(),
    ));
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.configure(
      onMessage: (message) {
        print(message);
        notifications.show(
          1,
          message['notification']['title'],
          message['notification']['body'],
          NotificationDetails(
            AndroidNotificationDetails(
              'general',
              'General notifications',
              '',
              importance: Importance.High,
            ),
            IOSNotificationDetails(),
          ),
        );
      },
    );
    _firebaseMessaging.getToken().then((value) => print(value));
  }

  void _setDark(bool value) async {
    setState(() {
      brightness = value ? Brightness.dark : Brightness.light;
    });
    await widget.prefs.setBool("isDark", value);
  }

  Widget _buildScreen(BuildContext context, BoxConstraints constraints) {
    return Material(
      elevation: 0.0,
      child: Backdrop(
        frontLayer: MyHomePage(),
        backLayer: Container(
          height: 100.0,
        ),
        fab: FloatingActionButton(
          onPressed: () {},
          tooltip: 'GO',
          child: Icon(Icons.smoking_rooms),
        ),
        settingsClick: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => SettingsPage(_setDark),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.fastOutSlowIn,
                    )),
                    child: child,
                  ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = brightness == Brightness.dark;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.orange,
          brightness: brightness,
          primaryColor: isDark ? null : Colors.white,
          toggleableActiveColor: Colors.orangeAccent[200],
          accentColor: Colors.orangeAccent[400]),
      home: LayoutBuilder(builder: _buildScreen),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Location location = Location();
  String _currentCode = "";

  @override
  void initState() {
    super.initState();
    location.onLocationChanged().listen((update) {
      setState(() {
        _currentCode =
            encode(update["latitude"], update["longitude"], codeLength: 8);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(_currentCode),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final ValueChanged<bool> darkModeCallback;

  SettingsPage(this.darkModeCallback);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  bool isDark;

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return SwitchListTile(
          title: const Text("Dark theme"),
          value: isDark,
          onChanged: (value) {
            widget.darkModeCallback(value);
            setState(() {
              isDark = value;
            });
          },
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView.builder(itemBuilder: _buildListItem),
    );
  }
}
