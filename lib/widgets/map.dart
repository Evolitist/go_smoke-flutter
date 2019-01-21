import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../services/prefs.dart';

class MapboxMap extends StatefulWidget {
  @override
  _MapboxMapState createState() => _MapboxMapState();
}

class _MapboxMapState extends State<MapboxMap> {
  final MapController _mapController = MapController();
  LatLng _latLng = LatLng(0.0, 0.0);

  LatLng _parse(List<String> data) {
    return LatLng(double.tryParse(data[0]), double.tryParse(data[1]));
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    _latLng = _parse(
      List.castFrom(
        PrefsModel.of(
          context,
          aspect: 'lastLoc',
          defaultValue: ['0.0', '0.0'],
        ),
      ),
    );
    if (_mapController.ready) _mapController.move(_latLng, 17.0);
    return Stack(
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
            center: _latLng,
            zoom: 17.0,
            interactive: false,
          ),
          layers: <LayerOptions>[
            TileLayerOptions(
              urlTemplate: "https://api.mapbox.com/v4/"
                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
              backgroundColor: isDark ? Color(0xff111111) : Color(0xffeeeeee),
              additionalOptions: {
                'accessToken':
                    'pk.eyJ1IjoiZXZvbGl0aXN0IiwiYSI6ImNqbWFkNTZnczA4enQzcm55djgzajdmd2UifQ.ZBP52x4Ed3tEbgODEMWE_w',
                'id': 'mapbox.${isDark ? 'dark' : 'light'}',
              },
            ),
            MarkerLayerOptions(
              markers: <Marker>[
                Marker(
                  point: _latLng,
                  builder: (context) => Material(
                        elevation: 4.0,
                        shape: CircleBorder(
                          side: BorderSide(color: Colors.white),
                        ),
                        color: Colors.blue,
                      ),
                  width: 16.0,
                  height: 16.0,
                  anchor: AnchorPos.center,
                ),
              ],
            ),
          ],
          mapController: _mapController,
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
        ),
      ],
    );
  }
}
