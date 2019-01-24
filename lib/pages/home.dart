import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../groups/chips.dart';
import '../olc.dart' as olc;
import '../services/auth.dart';
import '../services/location.dart';
import '../services/prefs.dart';
import '../widgets/backdrop.dart';
import '../widgets/map.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Location _location = Location();
  StreamSubscription _currentStream;
  List<Group> _groups;
  List<String> _lastLoc;
  double _lat;
  double _lng;

  @override
  void initState() {
    super.initState();
    _location.getLocationStream().then((stream) {
      _currentStream = stream.listen((update) {
        _lat = update.latitude;
        _lng = update.longitude;
        PrefsManager.of(context)
          ..set('lastLoc', <String>[
            _lat.toString(),
            _lng.toString(),
            update.accuracy.toString(),
          ])
          ..set('cell', olc.encode(_lat, _lng, codeLength: 8));
      })..onDone(() {
        if (_lastLoc == null) {
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
        }
      });
    });
  }

  @override
  void dispose() {
    _currentStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _groups = AuthModel.of(context, aspect: 'groups');
    return Backdrop(
      frontLayer: LiveMap(),
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
            objects: _groups,
            objectToName: (g) => g.name,
          ),
        ],
      ),
      fab: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text('Data to be sent'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'senderId: ${AuthModel.of(context, aspect: 'user').uid}',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'groups: ${PrefsModel.of(context, aspect: 'Groups')}',
                        textAlign: TextAlign.center,
                      ),
                      Text('senderLat: $_lat'),
                      Text('senderLng: $_lng'),
                    ],
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('OK'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
          );
          /*CloudFunctions.instance.call(
            functionName: 'performPrimaryAction',
            parameters: {
              'senderId': AuthModel.of(context, aspect: 'user').uid,
              'groups': <String>[],
              'senderLat': _lat,
              'senderLng': _lng,
            },
          );*/
        },
        tooltip: 'GO',
        child: Icon(Icons.smoking_rooms),
      ),
      settingsClick: () => Navigator.pushNamed(context, '/settings'),
      accountClick: () => Navigator.pushNamed(context, '/profile'),
    );
  }
}
