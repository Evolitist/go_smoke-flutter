import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backdrop.dart';
import 'groups/chips.dart';
import 'olc.dart';
import 'services/fcm.dart';
import 'utils.dart';

final Random _random = Random();
SharedPreferences _prefs;

void main() async {
  MaterialPageRoute.debugEnableFadingRoutes = true;
  _prefs = await SharedPreferences.getInstance();
  runApp(new App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final Geolocator _location = Geolocator();
  final FCM _fcm = FCM();
  final Trigger _fabTrigger = Trigger();
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
        backLayer: Material(
          elevation: 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ChoiceChipBlock(
                //TODO: decide if we want chips or something else for this control
                labelText: 'Cigarettes',
                selected: 1,
                names: <String>['none', '1', '2+'],
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
            MaterialPageRoute(
              builder: (context) => _SettingsPage(
                    _setDark,
                    _setDocked,
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
        accentColor: Colors.orangeAccent[400],
      ),
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
