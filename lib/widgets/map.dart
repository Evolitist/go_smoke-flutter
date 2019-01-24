import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../services/prefs.dart';

class LiveMap extends StatefulWidget {
  LiveMap({
    Key key,
    this.zoom: 17.0,
    this.onInteract,
  }) : super(key: key);

  final double zoom;

  final VoidCallback onInteract;

  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  final MapController _mapController = MapController();
  LatLng _latLng = LatLng(0.0, 0.0);

  //double _accuracy = 0.0;

  void _parse(List<String> data) {
    _latLng = LatLng(double.tryParse(data[0]), double.tryParse(data[1]));
    //_accuracy = double.tryParse(data[2]);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    _parse(
      List.castFrom(
        PrefsModel.of(
          context,
          aspect: 'lastLoc',
          defaultValue: ['0.0', '0.0', '0.0'],
        ),
      ),
    );
    if (_mapController.ready) _mapController.move(_latLng, widget.zoom);
    return Stack(
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
            center: _latLng,
            zoom: widget.zoom,
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
                //TODO: enable in future release
                /*Marker(
              point: _latLng,
              builder: (ctx) => Material(
                    elevation: 1.0,
                    shape: CircleBorder(
                      side: BorderSide(color: Colors.blue.withAlpha(127)),
                    ),
                    color: Colors.blue.withAlpha(31),
                  ),
              width: _accuracy /
                  8.0 *
                  (_mapController.ready ? _mapController.zoom : widget.zoom),
              height: _accuracy /
                  8.0 *
                  (_mapController.ready ? _mapController.zoom : widget.zoom),
              anchor: AnchorPos.center,
            ),*/
                Marker(
                  point: _latLng,
                  builder: (context) {
                    return Material(
                      elevation: 4.0,
                      shape: CircleBorder(
                        side: BorderSide(color: Colors.white),
                      ),
                      color: Colors.blue,
                    );
                  },
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
          onTap: widget.onInteract,
          behavior: HitTestBehavior.opaque,
        ),
      ],
    );
  }
}

class SelectorMap extends StatefulWidget {
  SelectorMap({
    Key key,
    this.zoom: 17.0,
    this.decoration,
    this.focusNode,
    this.onInteract,
  }) : super(key: key);

  final double zoom;

  final InputDecoration decoration;

  final FocusNode focusNode;

  final ValueChanged<LatLng> onInteract;

  @override
  _SelectorMapState createState() => _SelectorMapState();
}

class _SelectorMapState extends State<SelectorMap> {
  final MapController _mapController = MapController();
  LatLng _latLng = LatLng(0.0, 0.0);

  FocusNode _focusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  void _parse(List<String> data) {
    _latLng = LatLng(double.tryParse(data[0]), double.tryParse(data[1]));
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).reparentIfNeeded(_effectiveFocusNode);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    _parse(
      List.castFrom(
        PrefsModel.of(
          context,
          aspect: 'lastLoc',
          defaultValue: ['0.0', '0.0', '0.0'],
        ),
      ),
    );
    Widget result = CustomPaint(
      foregroundPainter: _ReticlePainter(
        strokeWidth: 1.0,
        color: isDark ? Colors.white : Colors.black,
        opacity: 0.9,
      ),
      child: FlutterMap(
        options: MapOptions(
          center: _latLng,
          zoom: widget.zoom,
          onPositionChanged: (pos, b) {
            if (b) {
              setState(() {});
              if (widget.onInteract != null) {
                widget.onInteract(pos.center);
              }
            }
          },
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
                builder: (context) {
                  return Material(
                    elevation: 4.0,
                    shape: CircleBorder(
                      side: BorderSide(color: Colors.white),
                    ),
                    color: Colors.blue,
                  );
                },
                width: 16.0,
                height: 16.0,
                anchor: AnchorPos.center,
              ),
            ],
          ),
        ],
        mapController: _mapController,
      ),
    );
    if (widget.decoration != null) {
      LatLng loc = _mapController.ready ? _mapController.center.round() : null;
      result = Padding(
        padding: EdgeInsets.only(bottom: 24.0),
        child: InputDecorator(
          isFocused: _effectiveFocusNode.hasFocus,
          decoration: widget.decoration.copyWith(
            counterText:
                loc != null ? '${loc.latitude}, ${loc.longitude}' : null,
          ),
          child: result,
        ),
      );
    }
    return Stack(
      children: <Widget>[
        result,
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) {
            FocusScope.of(context).requestFocus(_effectiveFocusNode);
            if (widget.onInteract != null) {
              widget.onInteract(null);
            }
          },
        ),
      ],
    );
  }
}

class _ReticlePainter extends CustomPainter {
  _ReticlePainter({
    this.strokeWidth: 8.0,
    this.color: Colors.black,
    this.opacity: 0.5,
  }) : assert(strokeWidth != null) {
    _paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(opacity)
      ..blendMode = BlendMode.srcOver;
  }

  final double strokeWidth;

  final Color color;

  final double opacity;

  Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        0.0,
        size.height / 2.0 - strokeWidth / 2.0,
        size.width,
        strokeWidth,
      ),
      _paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2.0 - strokeWidth / 2.0,
        0.0,
        strokeWidth,
        size.height / 2.0 - strokeWidth / 2.0,
      ),
      _paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2.0 - strokeWidth / 2.0,
        size.height / 2.0 + strokeWidth / 2.0,
        strokeWidth,
        size.height / 2.0 - strokeWidth / 2.0,
      ),
      _paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
