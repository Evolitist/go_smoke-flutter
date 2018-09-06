import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNotchedShape extends ShapeBorder {
  final double cornerRadius;
  final double notchRadius;
  final Rect guest;

  const BottomNotchedShape({
    this.cornerRadius: 28.0,
    this.notchRadius: 32.0,
    this.guest,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(0.0);

  List<Offset> _calculateCurves(Rect host, Rect guest) {
    const double s1 = 8.0;
    const double s2 = 1.0;

    final double r = notchRadius;
    final double a = -1.0 * r - s2;
    final double b = host.bottom - guest.center.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = -math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = -math.sqrt(r * r - p2xB * p2xB);

    final List<Offset> p = new List<Offset>(6);

    // p0, p1, and p2 are the control points for segment A.
    p[0] = new Offset(a - s1, b);
    p[1] = new Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB
        ? new Offset(p2xA, p2yA)
        : new Offset(p2xB, p2yB);

    // p3, p4, and p5 are the control points for segment B, which is a mirror
    // of segment A around the y axis.
    p[3] = new Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = new Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = new Offset(-1.0 * p[0].dx, p[0].dy);

    // translate all points back to the absolute coordinate system.
    for (int i = 0; i < p.length; i += 1) p[i] += guest.center;

    return p;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    if (notchRadius > 0.0) {
      final List<Offset> p = _simpleCalcCurves(notchRadius, rect.bottomCenter);
      return Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.left, rect.bottom - cornerRadius)
        ..relativeArcToPoint(
          Offset(cornerRadius, cornerRadius),
          radius: Radius.circular(cornerRadius),
          clockwise: false,
        )
        ..lineTo(p[0].dx, p[0].dy)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
        ..arcToPoint(
          p[3],
          radius: new Radius.circular(notchRadius),
          clockwise: true,
        )
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
        ..lineTo(rect.right - cornerRadius, rect.bottom)
        ..relativeArcToPoint(
          Offset(cornerRadius, -cornerRadius),
          radius: Radius.circular(cornerRadius),
          clockwise: false,
        )
        ..lineTo(rect.right, rect.top)
        ..close();
    } else {
      return Path()
        ..addRRect(RRect.fromRectAndCorners(
          rect,
          bottomLeft: Radius.circular(cornerRadius),
          bottomRight: Radius.circular(cornerRadius),
        ));
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return BottomNotchedShape(
      cornerRadius: cornerRadius * t,
      notchRadius: notchRadius * t,
    );
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is BottomNotchedShape) {
      return BottomNotchedShape(
        cornerRadius: lerpDouble(cornerRadius, b.cornerRadius, t),
        notchRadius: lerpDouble(notchRadius, b.notchRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is BottomNotchedShape) {
      return BottomNotchedShape(
        cornerRadius: lerpDouble(a.cornerRadius, cornerRadius, t),
        notchRadius: lerpDouble(a.notchRadius, notchRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }
}

List<Offset> _simpleCalcCurves(double notchRadius, Offset guest) {
  const double s1 = 8.0;
  const double s2 = 1.0;

  final double r = notchRadius;
  final double a = -1.0 * r - s2;

  final double p2x = (r * r) / (a);
  final double p2y = -math.sqrt(r * r - p2x * p2x);

  final List<Offset> p = new List<Offset>(6);

  p[0] = Offset(a - s1, 0.0);
  p[1] = Offset(a, 0.0);
  p[2] = Offset(p2x, p2y);
  p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
  p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
  p[5] = Offset(-1.0 * p[0].dx, p[0].dy);

  for (int i = 0; i < p.length; i += 1) p[i] += guest;

  return p;
}
