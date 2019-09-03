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
  const HomePage({Key key}) : super(key: key);

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
              title: const Text('Permissions error'),
              content: const Text('Location permission is reqired for app to work.'),
              actions: <Widget>[
                FlatButton(onPressed: () => SystemNavigator.pop(), child: const Text('OK')),
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
      frontLayer: const LiveMap(),
      backLayer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          /*ChoiceChipBlock(
            //TODO: decide if we want chips or something else for this control
            labelText: 'Cigarettes',
            selected: 1,
            names: <String>['none', '1', '2+'],
          ),
          const SizedBox(height: 16.0),*/
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
              title: const Text('Data to be sent'),
              content: Text(
                'senderId: ${AuthModel.of(context, aspect: 'user').uid}\ngroups: $_g',
                textAlign: TextAlign.center,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('OK'),
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
        child: const Icon(Icons.smoking_rooms),
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        Builder(
          builder: (ctx) {
            bool dark = PrefsModel.of(ctx, aspect: 'isDark', defaultValue: false);
            return AnimatedCrossFade(
              firstChild: IconButton(
                icon: const Icon(Icons.brightness_3),
                onPressed: () => PrefsManager.of(ctx).set('isDark', false),
              ),
              secondChild: IconButton(
                icon: const Icon(Icons.brightness_7),
                onPressed: () => PrefsManager.of(ctx).set('isDark', true),
              ),
              crossFadeState: dark ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: kThemeChangeDuration,
            );
          },
        ),
        /*IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),*/
      ],
    );
  }
}
