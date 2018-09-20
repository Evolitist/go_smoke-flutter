import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../backdrop.dart';
import '../groups/chips.dart';
import '../services/location.dart';
import '../services/prefs.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Prefs _prefs = Prefs();
  final Location _location = Location();
  final MapController _mapController = MapController();

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
    _prefs<List<String>>(
      'lastLoc',
      (a) {
        if (_mapController.ready) {
          _mapController.move(
            LatLng(
              double.tryParse(a[0]),
              double.tryParse(a[1]),
            ),
            17.0,
          );
        }
      },
      defaultValue: ['0.0', '0.0'],
    );
  }

  @override
  void dispose() {
    _prefs.stop('lastLoc');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      frontLayer: FlutterMap(
        options: MapOptions(
          zoom: 17.0,
        ),
        layers: <LayerOptions>[
          TileLayerOptions(
            urlTemplate: "https://api.mapbox.com/v4/"
                "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
            additionalOptions: {
              'accessToken':
                  'pk.eyJ1IjoiZXZvbGl0aXN0IiwiYSI6ImNqbWFkNTZnczA4enQzcm55djgzajdmd2UifQ.ZBP52x4Ed3tEbgODEMWE_w',
              'id': 'mapbox.streets',
            },
          ),
        ],
        mapController: _mapController,
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
      settingsClick: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(),
          ),
        );
      },
    );
  }
}
