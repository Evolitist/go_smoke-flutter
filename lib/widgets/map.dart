import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../services/auth.dart';
import '../services/prefs.dart';
import 'circle_layer.dart';

const List<String> _kDefParams = ['0.0', '0.0', '0.0'];

class LiveMap extends StatefulWidget {
  const LiveMap({
    Key key,
    this.zoom: 17,
    this.onInteract,
  }) : super(key: key);

  final double zoom;

  final VoidCallback onInteract;

  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  final MapController _mapController = MapController();
  LatLng _latLng = LatLng(0, 0);
  List<Group> _groups;
  List<dynamic> _selectedGroups;
  double _accuracy = 0;

  void _parse(List<String> data) {
    _latLng = LatLng(double.tryParse(data[0]), double.tryParse(data[1]));
    _accuracy = double.tryParse(data[2]);
  }

  double _metersToPixels(double meters, double latitude, double zoom) {
    return meters * 256 / (math.cos(degToRadian(latitude)) * (EARTH_RADIUS * 2 * PI) / math.pow(2, zoom));
  }

  @override
  Widget build(BuildContext context) {
    _groups = AuthModel.of(context, aspect: 'groups');
    _selectedGroups = PrefsModel.of(context, aspect: 'Groups', defaultValue: []);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    _parse(List.castFrom(PrefsModel.of(context, aspect: 'lastLoc', defaultValue: _kDefParams)));
    if (_mapController.ready) _mapController.move(_latLng, widget.zoom);
    return Stack(
      children: <Widget>[
        FlutterMap(
          options: MapOptions(center: _latLng, zoom: widget.zoom, plugins: [BorderCircleLayerPlugin()]),
          layers: <LayerOptions>[
            TileLayerOptions(
              urlTemplate: "https://api.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
              backgroundColor: isDark ? const Color(0xff111111) : const Color(0xffeeeeee),
              additionalOptions: {
                'accessToken': 'pk.eyJ1IjoiZXZvbGl0aXN0IiwiYSI6ImNqbWFkNTZnczA4enQzcm55djgzajdmd2UifQ.ZBP52x4Ed3tEbgODEMWE_w',
                'id': 'mapbox.${isDark ? 'dark' : 'light'}',
              },
            ),
            BorderCircleLayerOptions(
              circles: [
                ..._groups.map((group) {
                  bool selected = _selectedGroups.contains(group.uid);
                  return BorderCircleMarker(
                    point: group.location,
                    radius: _metersToPixels(100, group.location.latitude,
                        _mapController.ready ? _mapController.zoom : widget.zoom),
                    color: Colors.orange.withAlpha(selected ? 63 : 31),
                    hardBorder: selected,
                    borderWidth: selected ? 4 : 16,
                    borderColor: Colors.orange,
                  );
                }),
                BorderCircleMarker(
                  point: _latLng,
                  radius: _metersToPixels(
                      _accuracy,
                      _latLng.latitude,
                      _mapController.ready
                          ? _mapController.zoom
                          : widget.zoom,
                  ),
                  color: Colors.blue.withAlpha(31),
                  hardBorder: true,
                  borderWidth: 1,
                  borderColor: Colors.blue.withAlpha(127),
                ),
              ],
            ),
            MarkerLayerOptions(
              markers: [
                for (Group group in _groups)
                  Marker(
                    point: group.location,
                    builder: (ctx) => Center(child: Text(group.name)),
                    width: 128,
                    height: 128,
                    anchorPos: AnchorPos.align(AnchorAlign.center),
                  ),
              ],
            ),
            MarkerLayerOptions(
              markers: <Marker>[
                Marker(
                  point: _latLng,
                  builder: (_) => Material(
                    elevation: 4,
                    shape: const CircleBorder(side: BorderSide(color: Colors.white)),
                    color: Colors.blue,
                  ),
                  width: 16,
                  height: 16,
                  anchorPos: AnchorPos.align(AnchorAlign.center),
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
  const SelectorMap({
    Key key,
    this.zoom: 17,
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
  LatLng _latLng = LatLng(0, 0);

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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    _parse(List.castFrom(PrefsModel.of(context, aspect: 'lastLoc', defaultValue: _kDefParams)));
    Widget result = CustomPaint(
      foregroundPainter: _ReticlePainter(
        strokeWidth: 1,
        color: isDark ? Colors.white : Colors.black,
        opacity: 0.9,
      ),
      child: FlutterMap(
        options: MapOptions(
          center: _latLng,
          zoom: widget.zoom,
          onPositionChanged: (pos, b, b2) {
            if (b && b2) {
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
                builder: (ctx) => const Material(
                  elevation: 4,
                  shape: CircleBorder(side: BorderSide(color: Colors.white)),
                  color: Colors.blue,
                ),
                width: 16,
                height: 16,
                anchorPos: AnchorPos.align(AnchorAlign.center),
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
        padding: EdgeInsets.only(bottom: 24),
        child: InputDecorator(
          isFocused: _effectiveFocusNode.hasFocus,
          decoration: widget.decoration.copyWith(
            counterText: loc != null ? '${loc.latitude}, ${loc.longitude}' : null,
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
    this.strokeWidth: 8,
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
    final double hw = size.width / 2;
    final double hh = size.height / 2;
    final double hs = strokeWidth / 2;
    canvas.drawRect(Rect.fromLTWH(0, hh - hw, size.width, strokeWidth), _paint);
    canvas.drawRect(Rect.fromLTWH(hw - hs, 0, strokeWidth, hh - hs), _paint);
    canvas.drawRect(Rect.fromLTWH(hw - hs, hh + hs, strokeWidth, hh - hs), _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
