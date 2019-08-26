import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final List<String> _g = List();
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
                    FlatButton(onPressed: () => SystemNavigator.pop(), child: Text('OK')),
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
          StatefulBuilder(
            builder: (ctx, setBlockState) {
              _groups = AuthModel.of(ctx, aspect: 'groups');
              return FilterChipBlock(
                labelText: 'Groups',
                names: _groups.map((g) => g.name).toList(growable: false),
                states: _groups.map((g) => _g.contains(g.uid)).toList(growable: false),
                enabled: (i) => _lat != null && _lng != null ? _groups[i].inCallRange(_lat, _lng) : false,
                onSelected: (i) => setBlockState(() {
                  if (_g.contains(_groups[i].uid)) {
                    _g.remove(_groups[i].uid);
                  } else {
                    _g.add(_groups[i].uid);
                  }
                }),
              );
            }
          ),
        ],
      ),
      fab: FloatingActionButton(
        onPressed: () async {
          await showDialog(
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
                        'groups: $_g',
                        textAlign: TextAlign.center,
                      ),
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
          /*CloudFunctions.instance.getHttpsCallable(functionName: 'performPrimaryAction').call({
            'senderId': AuthModel.of(context, aspect: 'user').uid,
            'groups': _g,
            'senderLat': _lat,
            'senderLng': _lng,
          }).then((result) {
            print(result.data);
          }, onError: (e) {
            if (e is CloudFunctionsException) {
              print(e.code);
              print(e.message);
              print(e.details);
            }
          });*/
        },
        tooltip: 'GO',
        child: Icon(Icons.smoking_rooms),
      ),
      settingsClick: () => Navigator.pushNamed(context, '/settings'),
      accountClick: () => Navigator.pushNamed(context, '/profile'),
    );
  }
}
