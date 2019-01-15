import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../shapes.dart';
import '../transitions.dart';
import '../utils.dart';

const double _kFlingVelocity = 2.0;
const double _kAppBarSizePortrait = 56.0;
const double _kAppBarSizeLandscape = 48.0;

class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final Widget backLayer;
  final Widget bottomSheet;
  final FloatingActionButton fab;
  final VoidCallback settingsClick;
  final VoidCallback accountClick;
  final Trigger fabTrigger;

  const Backdrop({
    @required this.frontLayer,
    @required this.backLayer,
    this.bottomSheet,
    this.fab,
    this.fabTrigger,
    this.settingsClick,
    this.accountClick,
  })  : assert(frontLayer != null),
        assert(backLayer != null);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with TickerProviderStateMixin {
  final SizeSavingDelegate _delegate = SizeSavingDelegate();
  AnimationController _layerController;
  AnimationController _fabController;
  AnimationController _bottomSheetController;
  ShapeBorder _layerShape = BottomNotchedShape();
  bool _bottomSheetVisible = false;
  double _size;
  double _dragOffset;

  @override
  void initState() {
    super.initState();
    _layerController = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
    _fabController = AnimationController(
      duration: Duration(microseconds: 262500),
      value: 1.0,
      vsync: this,
    );
    _bottomSheetController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    )..addStatusListener((status) {
        setState(() {
          _bottomSheetVisible = status != AnimationStatus.dismissed;
        });
      });
    widget.fabTrigger?.addListener(_toggleFab);
  }

  @override
  void dispose() {
    widget.fabTrigger?.removeListener(_toggleFab);
    _layerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final AnimationStatus status = _layerController.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBackdropLayerVisibility() {
    _layerController.fling(
        velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  bool get _fabVisible {
    final AnimationStatus status = _fabController.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleFab() {
    setState(() {
      _layerShape = BottomNotchedShape(notchRadius: _fabVisible ? 0.0 : 32.0);
    });
    if (!_fabVisible) {
      Future.delayed(
        Duration(microseconds: 37500),
        () => _fabController.fling(velocity: _kFlingVelocity),
      );
    } else {
      _fabController.fling(velocity: -_kFlingVelocity);
    }
  }

  void _toggleBottomSheetVisibility() {
    _bottomSheetController.fling(
        velocity: _bottomSheetVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  Widget _buildFrontLayer(BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _delegate.childHeight + _size),
      end: EdgeInsets.only(bottom: _size),
    ).animate(_layerController.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: Material(
        animationDuration: Duration(milliseconds: 300),
        elevation: widget.fab.elevation,
        clipBehavior: Clip.antiAlias,
        shape: _layerShape,
        child: widget.frontLayer,
      ),
    );
  }

  Widget _buildGestureDetector(
      BuildContext context, BoxConstraints constraints) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        RenderBox box = context.findRenderObject();
        _dragOffset = box.globalToLocal(details.globalPosition).dy;
      },
      onVerticalDragUpdate: (details) {
        _layerController.value = (details.globalPosition.dy -
                _delegate.diffHeight +
                _dragOffset +
                _size) /
            _delegate.childHeight;
      },
      onVerticalDragEnd: (details) {
        if (_layerController.value != 1.0 && _layerController.value != 0.0) {
          if (details.primaryVelocity != 0) {
            _layerController.fling(
                velocity: details.primaryVelocity / _delegate.childHeight);
          } else {
            final double velocity = _layerController.value < 0.5 ? -1.0 : 1.0;
            _layerController.fling(velocity: velocity);
          }
        }
      },
    );
  }

  Widget _buildGestureDetectorContainer(
      BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _delegate.childHeight + _size),
      end: EdgeInsets.only(bottom: _size),
    ).animate(_layerController.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: Container(
        height: 32.0,
        child: LayoutBuilder(builder: _buildGestureDetector),
      ),
    );
  }

  Widget _buildFab(BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _delegate.childHeight + 28.0),
      end: EdgeInsets.only(bottom: _size - 28.0),
    ).animate(_layerController.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: ScaleTransition(
        scale: _fabController.view,
        child: widget.fab,
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
    ).animate(_layerController.view);
    Animation<Offset> bottomSheetAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(_bottomSheetController.view);
    return WillPopScope(
      onWillPop: () {
        if (_bottomSheetVisible) {
          _toggleBottomSheetVisibility();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Material(
        elevation: 0.0,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            FadeTransition(
              opacity: backAnimation,
              child: CustomSingleChildLayout(
                delegate: _delegate,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: _size,
                  ),
                  child: widget.backLayer,
                ),
              ),
            ),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.close_menu,
                      progress: _layerController.view,
                    ),
                    onPressed: _toggleBackdropLayerVisibility,
                  ),
                  Expanded(
                    child: Container(height: _size),
                  ),
                  IconButton(
                    icon: Icon(Icons.person),
                    onPressed: widget.accountClick ??
                        () => _toggleBottomSheetVisibility(),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: widget.settingsClick,
                  ),
                ],
              ),
            ),
            LayoutBuilder(builder: _buildFrontLayer),
            LayoutBuilder(builder: _buildGestureDetectorContainer),
            LayoutBuilder(builder: _buildFab),
            FadeTransition(
              opacity: _bottomSheetController.view,
              child: IgnorePointer(
                ignoring: !_bottomSheetVisible,
                child: Container(
                  color: Colors.black.withAlpha(192),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleBottomSheetVisibility,
                  ),
                ),
              ),
            ),
            SlideTransition(
              position: bottomSheetAnimation,
              child: widget.bottomSheet,
            ),
          ],
        ),
      ),
    );
  }
}
