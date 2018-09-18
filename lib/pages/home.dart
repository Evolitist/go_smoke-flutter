import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_smoke/backdrop.dart';
import 'package:go_smoke/groups/chips.dart';
import 'package:go_smoke/olc.dart';
import 'package:go_smoke/services/location.dart';
import 'package:go_smoke/utils.dart';

import 'settings.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Trigger _fabTrigger = Trigger();
  final Location _location = Location();
  String _currentCode;

  @override
  void initState() {
    super.initState();
    _location.getLocationStream().then((option) {
      option.cata(
        () {
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
        },
        (stream) {
          stream.listen((update) {
            setState(() {
              _currentCode = encode(
                update.latitude,
                update.longitude,
                codeLength: 8,
              );
            });
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
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
                names: ['one', 'two', 'three'],
              ),
            ],
          ),
        ),
        fab: FloatingActionButton(
          onPressed: () {},
          tooltip: 'GO',
          child: Icon(Icons.smoking_rooms),
        ),
        dockFab: false,
        fabTrigger: _fabTrigger,
        settingsClick: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsPage(),
            ),
          );
        },
      ),
    );
  }
}
