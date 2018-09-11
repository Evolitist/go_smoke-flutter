import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backdrop.dart';
import 'olc.dart';
import 'utils.dart';

SharedPreferences _prefs;

void main() async {
  _prefs = await SharedPreferences.getInstance();
  runApp(new App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final Location location = Location();
  final Trigger _fabTrigger = Trigger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  String _currentCode = "";
  Brightness brightness =
      (_prefs.getBool("isDark") ?? false) ? Brightness.dark : Brightness.light;
  bool docked = _prefs.getBool("docked") ?? false;

  @override
  void initState() {
    super.initState();
    notifications.initialize(InitializationSettings(
      AndroidInitializationSettings('ic_notification'),
      IOSInitializationSettings(),
    ));
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
      ),
    );
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
    location.hasPermission().then((value) {
      if (value) {
        location.onLocationChanged().listen((update) {
          setState(() {
            _currentCode = encode(
              update["latitude"],
              update["longitude"],
              codeLength: 8,
            );
          });
        });
      }
    });
  }

  bool get _isDark => brightness == Brightness.dark;

  void _setDark(bool value) async {
    setState(() {
      brightness = value ? Brightness.dark : Brightness.light;
    });
    _prefs.setBool("isDark", value);
  }

  void _setDocked(bool value) async {
    setState(() {
      docked = value;
    });
    _prefs.setBool("docked", value);
  }

  Widget _buildScreen(BuildContext context, BoxConstraints constraints) {
    return Container(
      color: _isDark ? Colors.grey[850] : Colors.grey[50],
      child: Backdrop(
        frontLayer: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(_currentCode),
            RaisedButton(
              onPressed: () {
                _fabTrigger.fire();
              },
              child: Text('ANIMATE'),
            ),
          ],
        ),
        backLayer: Container(
          height: 100.0,
        ),
        fab: FloatingActionButton(
          onPressed: () {},
          tooltip: 'GO',
          child: Icon(Icons.smoking_rooms),
        ),
        dockFab: docked,
        fabTrigger: _fabTrigger,
        settingsClick: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => SettingsPage(
                    _setDark,
                    _setDocked,
                  ),
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

class SettingsPage extends StatefulWidget {
  final ValueChanged<bool> darkModeCallback;
  final ValueChanged<bool> dockFabCallback;

  SettingsPage(this.darkModeCallback, this.dockFabCallback);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  bool isDark;
  bool dockFab;

  @override
  void initState() {
    super.initState();
    isDark = _prefs.getBool("isDark") ?? false;
    dockFab = _prefs.getBool("docked") ?? false;
  }

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
      case 1:
        return SwitchListTile(
          title: const Text("Dock FAB"),
          value: dockFab,
          onChanged: (value) {
            widget.dockFabCallback(value);
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
