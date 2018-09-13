import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backdrop.dart';
import 'groups/chips.dart';
import 'olc.dart';
import 'utils.dart';

final Random _random = Random();
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
  final Geolocator _location = Geolocator();
  final Trigger _fabTrigger = Trigger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  String _currentCode = "";
  Brightness _brightness =
      (_prefs.getBool("isDark") ?? false) ? Brightness.dark : Brightness.light;
  bool _docked = _prefs.getBool("docked") ?? false;
  List<String> _groups = <String>[
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight'
  ];

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
    _initLocation();
  }

  void _initLocation() async {
    _location.checkGeolocationPermissionStatus().then((value) async {
      print(value);
      if (value != GeolocationStatus.granted &&
          value != GeolocationStatus.restricted) {
        try {
          await _location.getCurrentPosition();
        } catch (e) {
          print(e);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Permissions error'),
                  content:
                      Text('Location permission is reqired for app to work.'),
                  actions: <Widget>[
                    FlatButton(onPressed: () => exit(0), child: Text('OK')),
                  ],
                ),
          );
          return;
        }
      }
      _location
          .getPositionStream(
            LocationOptions(
              accuracy: LocationAccuracy.high,
              distanceFilter: 20,
            ),
          )
          .then((value) => value.listen((update) {
                setState(() {
                  _currentCode = encode(
                    update.latitude,
                    update.longitude,
                    codeLength: 8,
                  );
                });
              }));
    });
  }

  bool get _isDark => _brightness == Brightness.dark;

  void _setDark(bool value) async {
    setState(() {
      _brightness = value ? Brightness.dark : Brightness.light;
    });
    _prefs.setBool("isDark", value);
  }

  void _setDocked(bool value) async {
    setState(() {
      _docked = value;
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    setState(() {
                      _groups.add(String.fromCharCodes(List.generate(
                          3 + _random.nextInt(5),
                          (i) => 0x61 + _random.nextInt(26))));
                    });
                  },
                  child: Text('+GROUP'),
                ),
                RaisedButton(
                  onPressed: () {
                    setState(() {
                      _groups.removeLast();
                    });
                  },
                  child: Text('-GROUP'),
                ),
              ],
            ),
          ],
        ),
        backLayer: Padding(
          padding: EdgeInsets.only(top: 44.0, left: 16.0, right: 16.0),
          child: Material(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ChoiceChipBlock(
                  //TODO: decide if we want chips or something else for this control
                  labelText: 'Spare cigarettes',
                  iconFont: true,
                  names: <String>[
                    String.fromCharCode(0xeb4a),
                    String.fromCharCode(0xeb4b),
                    String.fromCharCodes(<int>[
                      0xeb4b,
                      0xeb4b,
                    ]),
                    String.fromCharCodes(<int>[
                      0xeb4b,
                      0xeb4b,
                      0xeb4b,
                    ]),
                  ],
                ),
                Container(
                  height: 16.0,
                ),
                FilterChipBlock(
                  labelText: 'Groups',
                  names: _groups,
                ),
              ],
            ),
          ),
        ),
        fab: FloatingActionButton(
          onPressed: () {},
          tooltip: 'GO',
          child: Icon(Icons.smoking_rooms),
        ),
        dockFab: _docked,
        fabTrigger: _fabTrigger,
        settingsClick: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => _SettingsPage(
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
    bool isDark = _brightness == Brightness.dark;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.orange,
          brightness: _brightness,
          primaryColor: isDark ? null : Colors.white,
          toggleableActiveColor: Colors.orangeAccent[200],
          accentColor: Colors.orangeAccent[400]),
      home: LayoutBuilder(builder: _buildScreen),
    );
  }
}

class _SettingsPage extends StatefulWidget {
  final ValueChanged<bool> darkModeCallback;
  final ValueChanged<bool> dockFabCallback;

  _SettingsPage(this.darkModeCallback, this.dockFabCallback);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<_SettingsPage> {
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
