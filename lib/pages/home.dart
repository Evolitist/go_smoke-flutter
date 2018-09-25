import 'dart:io';

import 'package:flutter/material.dart';

import '../groups/chips.dart';
import '../services/location.dart';
import '../services/prefs.dart';
import '../widgets/backdrop.dart';
import '../widgets/map.dart';
import '../widgets/user_card.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Prefs _prefs = Prefs();
  final Location _location = Location();

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
            _prefs['lastLoc'] = <String>[
              update.latitude.toString(),
              update.longitude.toString(),
            ];
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _prefs.stop('lastLoc');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      frontLayer: MapboxMap(),
      backLayer: Column(
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
      fab: FloatingActionButton(
        onPressed: () {},
        tooltip: 'GO',
        child: Icon(Icons.smoking_rooms),
      ),
      settingsClick: () => Navigator.pushNamed(context, '/settings'),
      bottomSheet: UserCard(),
    );
  }
}
