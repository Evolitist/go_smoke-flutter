import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'shapes.dart';
import 'transitions.dart';
import 'utils.dart';

const double _kFlingVelocity = 2.0;
const double _kAppBarSizePortrait = 56.0;
const double _kAppBarSizeLandscape = 48.0;
final _FrontLayerKey frontLayerKey = _FrontLayerKey();

class _FrontLayerKey extends GlobalKey<_FrontLayerState> {
  _FrontLayerKey() : super.constructor();

  void toggleFab() {
    currentState._toggleFab();
  }
}

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
  final SizeSavingDelegate _delegate = SizeSavingDelegate();
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
      begin: EdgeInsets.only(bottom: _delegate.childHeight),
      end: EdgeInsets.all(0.0),
    ).animate(_controller.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: _FrontLayer(
        key: frontLayerKey,
        child: widget.frontLayer,
        fab: widget.fab,
        size: _size,
        dragStart: (value) => _dragOffset = value,
        dragUpdate: (details) {
          _controller.value =
              (details.globalPosition.dy - _delegate.diffHeight + _dragOffset) /
                  _delegate.childHeight;
        },
        dragEnd: (details) {
          if (_controller.value != 1.0 && _controller.value != 0.0) {
            if (details.primaryVelocity != 0) {
              _controller.fling(
                  velocity: details.primaryVelocity / _delegate.childHeight);
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
    Animation<double> backAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_controller.view);
    return Stack(
      children: <Widget>[
        Scaffold(
          bottomNavigationBar: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.close_menu,
                  progress: _controller.view,
                ),
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
              delegate: _delegate,
              child: widget.backLayer,
            ),
          ),
        ),
        LayoutBuilder(builder: _buildFrontLayer),
      ],
    );
  }
}

class _FrontLayer extends StatefulWidget {
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

  @override
  _FrontLayerState createState() => _FrontLayerState();
}

class _FrontLayerState extends State<_FrontLayer>
    with SingleTickerProviderStateMixin {
  final SizeSavingDelegate _stackDelegate = SizeSavingDelegate();
  AnimationController _controller;
  BottomNotchedShape _currentShape = BottomNotchedShape();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(microseconds: 262500),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _fabVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleFab() {
    setState(() {
      _currentShape = _fabVisible
          ? BottomNotchedShape(notchRadius: 0.0)
          : BottomNotchedShape();
    });
    if (!_fabVisible) {
      Future.delayed(
        Duration(microseconds: 37500),
        () => _controller.fling(velocity: _kFlingVelocity),
      );
    } else {
      _controller.fling(velocity: -_kFlingVelocity);
    }
  }

  Widget _buildGestureDetector(
      BuildContext context, BoxConstraints constraints) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        RenderBox box = context.findRenderObject();
        widget.dragStart(box.globalToLocal(details.globalPosition).dy);
      },
      onVerticalDragUpdate: widget.dragUpdate,
      onVerticalDragEnd: widget.dragEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _stackDelegate,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: widget.size),
            child: Material(
              animationDuration: Duration(milliseconds: 300),
              elevation: widget.fab.elevation,
              shape: _currentShape,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: widget.size),
            height: 28.0,
            child: LayoutBuilder(builder: _buildGestureDetector),
          ),
          Positioned(
            bottom: widget.size - 28.0,
            width: 56.0,
            height: 56.0,
            child: ScaleTransition(
              scale: _controller.view,
              child: widget.fab,
            ),
          ),
        ],
      ),
    );
  }
}
