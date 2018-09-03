import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

const double _kFlingVelocity = 2.0;
const double _kAppBarSizePortrait = 56.0;
const double _kAppBarSizeLandscape = 48.0;

class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final Widget backLayer;
  final Widget fab;

  const Backdrop({
    @required this.frontLayer,
    @required this.backLayer,
    this.fab,
  })  : assert(frontLayer != null),
        assert(backLayer != null);

  @override
  _BackdropState createState() => _BackdropState();
}

class _CustomShape extends ShapeBorder {
  final double cornerRadius;
  final double notchMargin;
  final double fabRadius;

  const _CustomShape({this.cornerRadius: 28.0, this.notchMargin: 4.0, this.fabRadius: 28.0});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(0.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    //final double notchRadius = 28.0 + notchMargin;
    //final double bezierY = notchRadius * 4.0 / 3.0;
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom - cornerRadius)
      ..relativeArcToPoint(Offset(cornerRadius, cornerRadius),
          radius: Radius.circular(cornerRadius), clockwise: false)
      //..lineTo(rect.bottomCenter.dx - notchRadius, rect.bottom)
      //..relativeCubicTo(0.0, -bezierY, notchRadius * 2, -bezierY, notchRadius * 2, 0.0)
      ..lineTo(rect.right - cornerRadius, rect.bottom)
      ..relativeArcToPoint(Offset(cornerRadius, -cornerRadius),
          radius: Radius.circular(cornerRadius), clockwise: false)
      ..lineTo(rect.right, rect.top)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    final double notchRadius = fabRadius + notchMargin;
    final double bezierY = notchRadius * 4.0 / 3.0;
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom - cornerRadius)
      ..relativeArcToPoint(Offset(cornerRadius, cornerRadius),
          radius: Radius.circular(cornerRadius), clockwise: false)
      ..lineTo(rect.bottomCenter.dx - notchRadius, rect.bottom)
      ..relativeCubicTo(0.0, -bezierY, notchRadius * 2, -bezierY, notchRadius * 2, 0.0)
      ..lineTo(rect.right - cornerRadius, rect.bottom)
      ..relativeArcToPoint(Offset(cornerRadius, -cornerRadius),
          radius: Radius.circular(cornerRadius), clockwise: false)
      ..lineTo(rect.right, rect.top)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _CustomShape(
        cornerRadius: cornerRadius * t,
        notchMargin: notchMargin * t,
        fabRadius: fabRadius * t);
  }
}

typedef void DoubleCallback(double value);

class _FrontLayer extends StatelessWidget {
  const _FrontLayer({
    Key key,
    this.dragStart,
    this.dragUpdate,
    this.dragEnd,
    this.child,
    this.fab,
    this.size,
  }) : super(key: key);

  final DoubleCallback dragStart;
  final GestureDragUpdateCallback dragUpdate;
  final GestureDragEndCallback dragEnd;
  final Widget child;
  final FloatingActionButton fab;
  final double size;

  Widget _buildGestureDetector(BuildContext context, BoxConstraints constraints) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        RenderBox box = context.findRenderObject();
        dragStart(box.globalToLocal(details.globalPosition).dy);
      },
      onVerticalDragUpdate: dragUpdate,
      onVerticalDragEnd: dragEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(bottom: size),
          child: Material(
            elevation: fab.elevation,
            shape: _CustomShape(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: size),
          height: 28.0,
          child: LayoutBuilder(builder: _buildGestureDetector),
        ),
        Positioned(bottom: size - 28.0, child: fab),
      ],
    );
  }
}

class Delegate extends SingleChildLayoutDelegate {
  double childHeight = 0.0;
  double diffHeight = 0.0;

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    Delegate old = oldDelegate as Delegate;
    return old.childHeight != childHeight || old.diffHeight != diffHeight;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    childHeight = childSize.height;
    diffHeight = size.height - childHeight;
    return Offset(0.0, diffHeight);
  }
}

class PaddingTransition extends AnimatedWidget {
  const PaddingTransition({
    Key key,
    @required Animation<EdgeInsets> padding,
    this.child,
  }) : super(key: key, listenable: padding);

  Animation<EdgeInsets> get padding => listenable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.value,
      child: child,
    );
  }
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');

  final Delegate _backDelegate = Delegate();
  AnimationController _controller;
  double _size;
  double _dragOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBackdropLayerVisibility() {
    _controller.fling(
        velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  Widget _buildFrontLayer(BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _backDelegate.childHeight),
      end: EdgeInsets.all(0.0),
    ).animate(_controller.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: _FrontLayer(
        child: widget.frontLayer,
        fab: widget.fab,
        size: _size,
        dragStart: (value) => _dragOffset = value,
        dragUpdate: (details) {
          _controller.value =
              (details.globalPosition.dy - _backDelegate.diffHeight + _dragOffset) /
                  _backDelegate.childHeight;
        },
        dragEnd: (details) {
          if (_controller.value != 1.0 && _controller.value != 0.0) {
            if (details.primaryVelocity != 0) {
              _controller.fling(
                  velocity:
                      details.primaryVelocity / _backDelegate.childHeight);
            } else {
              final double velocity = _controller.value < 0.5 ? -1.0 : 1.0;
              _controller.fling(velocity: velocity);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).orientation == Orientation.portrait
        ? _kAppBarSizePortrait
        : _kAppBarSizeLandscape;
    Animation<double> backAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_controller.view);
    return Stack(
      children: <Widget>[
        Scaffold(
          bottomNavigationBar: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: _toggleBackdropLayerVisibility,
              ),
              Container(height: _size),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
          body: FadeTransition(
            opacity: backAnimation,
            child: CustomSingleChildLayout(
              delegate: _backDelegate,
              child: widget.backLayer,
            ),
          ),
        ),
        LayoutBuilder(builder: _buildFrontLayer),
      ],
    );
  }
}
