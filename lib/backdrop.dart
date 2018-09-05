import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'shapes.dart';
import 'transitions.dart';
import 'utils.dart';

const double _kFlingVelocity = 2.0;
const double _kAppBarSizePortrait = 56.0;
const double _kAppBarSizeLandscape = 48.0;

class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final Widget backLayer;
  final Widget fab;
  final VoidCallback settingsClick;

  const Backdrop({
    @required this.frontLayer,
    @required this.backLayer,
    this.fab,
    this.settingsClick,
  })  : assert(frontLayer != null),
        assert(backLayer != null);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');

  final SizeSavingDelegate _backDelegate = SizeSavingDelegate();
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
          _controller.value = (details.globalPosition.dy -
                  _backDelegate.diffHeight +
                  _dragOffset) /
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
                onPressed: widget.settingsClick,
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

  final ValueChanged<double> dragStart;
  final GestureDragUpdateCallback dragUpdate;
  final GestureDragEndCallback dragEnd;
  final Widget child;
  final FloatingActionButton fab;
  final double size;

  Widget _buildGestureDetector(
      BuildContext context, BoxConstraints constraints) {
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
            shape: BottomNotchedShape(),
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
