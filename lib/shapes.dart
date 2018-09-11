import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNotchedShape extends ShapeBorder {
  final double cornerRadius;
  final double notchRadius;

  const BottomNotchedShape({
    this.cornerRadius: 28.0,
    this.notchRadius: 32.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(0.0);

  List<Offset> _simpleCalcCurves(Offset guest) {
    const double s1 = 8.0;
    const double s2 = 1.0;

    final double a = -notchRadius - s2;

    final double p2x = (notchRadius * notchRadius) / a;
    final double p2y = -math.sqrt(notchRadius * notchRadius - p2x * p2x);

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

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    if (notchRadius > 0.0) {
      final List<Offset> p = _simpleCalcCurves(rect.bottomCenter);
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

class TopNotchedShape extends ShapeBorder {
  final double cornerRadius;
  final double notchRadius;

  const TopNotchedShape({
    this.cornerRadius: 0.0,
    this.notchRadius: 32.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(0.0);

  List<Offset> _simpleCalcCurves(Offset guest) {
    const double s1 = 8.0;
    const double s2 = 1.0;

    final double a = -notchRadius - s2;

    final double p2x = (notchRadius * notchRadius) / a;
    final double p2y = math.sqrt(notchRadius * notchRadius - p2x * p2x);

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

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    if (notchRadius > 0.0) {
      final List<Offset> p = _simpleCalcCurves(rect.topCenter);
      return Path()
        ..moveTo(rect.left, rect.top + cornerRadius)
        ..relativeArcToPoint(
          Offset(cornerRadius, -cornerRadius),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(p[0].dx, p[0].dy)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
        ..arcToPoint(
          p[3],
          radius: Radius.circular(notchRadius),
          clockwise: false,
        )
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
        ..lineTo(rect.right - cornerRadius, rect.top)
        ..relativeArcToPoint(
          Offset(cornerRadius, cornerRadius),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
    } else {
      return Path()
        ..addRRect(RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(cornerRadius),
          topRight: Radius.circular(cornerRadius),
        ));
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return TopNotchedShape(
      cornerRadius: cornerRadius * t,
      notchRadius: notchRadius * t,
    );
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is TopNotchedShape) {
      return TopNotchedShape(
        cornerRadius: lerpDouble(cornerRadius, b.cornerRadius, t),
        notchRadius: lerpDouble(notchRadius, b.notchRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is TopNotchedShape) {
      return TopNotchedShape(
        cornerRadius: lerpDouble(a.cornerRadius, cornerRadius, t),
        notchRadius: lerpDouble(a.notchRadius, notchRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }
}
