import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart' hide Path;

class BorderCircleLayerPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return BorderCircleLayer(options, mapState);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is BorderCircleLayerOptions;
  }
}

class BorderCircleLayerOptions extends LayerOptions {
  final List<BorderCircleMarker> circles;

  BorderCircleLayerOptions({this.circles = const []});
}

class BorderCircleMarker {
  BorderCircleMarker({
    this.point,
    this.radius,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });

  final LatLng point;
  final double radius;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  Offset offset = Offset.zero;
}

class BorderCircleLayer extends StatelessWidget {
  BorderCircleLayer(this.circleOpts, this.map);

  final BorderCircleLayerOptions circleOpts;
  final MapState map;

  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<int>(
      stream: map.onMoved,
      builder: (BuildContext context, _) {
        return Container(
          child: Stack(
            children: circleOpts.circles.map((circle) {
              var pos = map.project(circle.point);
              pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
                  map.getPixelOrigin();
              circle.offset = Offset(pos.x.toDouble(), pos.y.toDouble());
              return CustomPaint(
                painter: CirclePainter(circle),
                size: size,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter(this.circle);

  final BorderCircleMarker circle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = circle.color;

    canvas.drawCircle(circle.offset, circle.radius, paint);
    if (circle.borderStrokeWidth > 0.0) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = circle.borderColor
        ..strokeWidth = circle.borderStrokeWidth;
      canvas.drawCircle(circle.offset, circle.radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(CirclePainter other) => false;
}
