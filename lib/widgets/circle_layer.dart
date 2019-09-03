import 'dart:ui';

import 'package:flutter/material.dart' hide Gradient;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart' hide Path;

class BorderCircleLayerPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
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
    @required this.point,
    @required this.radius,
    this.color: const Color(0xFF00FF00),
    this.hardBorder: false,
    this.borderWidth: 0,
    this.borderColor: const Color(0xFFFFFF00),
  }) : assert(color != null),
        assert(borderWidth != null);

  final LatLng point;
  final double radius;
  final Color color;
  final bool hardBorder;
  final double borderWidth;
  final Color borderColor;
  Offset offset = Offset.zero;
}

class BorderCircleLayer extends StatelessWidget {
  BorderCircleLayer(this.circleOpts, this.map);

  final BorderCircleLayerOptions circleOpts;
  final MapState map;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<void>(
      stream: map.onMoved,
      builder: (BuildContext context, _) {
        return Container(
          child: Stack(
            children: [
              ...circleOpts.circles.map((circle) {
                CustomPoint pos = map.project(circle.point);
                pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) - map.getPixelOrigin();
                circle.offset = Offset(pos.x.toDouble(), pos.y.toDouble());
                return CustomPaint(painter: CirclePainter(circle, map.zoom), size: size);
              })
            ],
          ),
        );
      },
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter(this.circle, this.zoom);

  final BorderCircleMarker circle;
  final double zoom;

  void _drawFill(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = circle.color;
    canvas.drawCircle(
      circle.offset,
      circle.radius - circle.borderWidth / 2,
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    if (circle.hardBorder) {
      _drawFill(canvas);
      if (circle.borderWidth > 0) {
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = circle.borderColor
          ..strokeWidth = circle.borderWidth;
        canvas.drawCircle(circle.offset, circle.radius, borderPaint);
      }
    } else {
      if (circle.borderWidth > 0) {
        final gradientPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = circle.color.withOpacity(1)
          ..shader = Gradient.radial(
            circle.offset,
            circle.radius,
            <Color>[
              circle.color,
              Colors.transparent,
            ],
            <double>[
              circle.radius / (circle.radius + circle.borderWidth),
              1,
            ],
          );
        canvas.drawCircle(circle.offset, circle.radius, gradientPaint);
      } else {
        _drawFill(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(CirclePainter other) => zoom != other.zoom;
}
