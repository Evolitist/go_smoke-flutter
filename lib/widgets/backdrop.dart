import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../shapes.dart';
import '../transitions.dart';

const double _kFlingVelocity = 2.0;
const double _kAppBarSizePortrait = 56.0;
const double _kAppBarSizeLandscape = 48.0;

class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final Widget backLayer;
  final FloatingActionButton fab;
  final ValueNotifier<bool> fabTrigger;
  final List<Widget> actions;

  const Backdrop({
    @required this.frontLayer,
    @required this.backLayer,
    this.fab,
    this.fabTrigger,
    this.actions,
  })  : assert(frontLayer != null),
        assert(backLayer != null);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with TickerProviderStateMixin {
  final _SizeSavingDelegate _delegate = _SizeSavingDelegate();
  AnimationController _layerController;
  AnimationController _fabController;
  ShapeBorder _layerShape = BottomNotchedShape();
  double _size;
  double _dragOffset;

  @override
  void initState() {
    super.initState();
    _layerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 1,
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(microseconds: 262500),
      value: 1,
      vsync: this,
    );
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
    return status == AnimationStatus.completed || status == AnimationStatus.forward;
  }

  void _toggleBackdropLayerVisibility() {
    _layerController.fling(velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  bool get _fabVisible {
    final AnimationStatus status = _fabController.status;
    return status == AnimationStatus.completed || status == AnimationStatus.forward;
  }

  void _toggleFab() {
    setState(() {
      _layerShape = BottomNotchedShape(notchRadius: _fabVisible ? 0 : 32);
    });
    if (widget.fabTrigger.value != _fabVisible) {
      if (!_fabVisible) {
        Future.delayed(
          const Duration(microseconds: 37500),
          () => _fabController.fling(velocity: _kFlingVelocity),
        );
      } else {
        _fabController.fling(velocity: -_kFlingVelocity);
      }
    }
  }

  Widget _buildFrontLayer(BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _delegate.childHeight + _size),
      end: EdgeInsets.only(bottom: _size),
    ).animate(_layerController.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: Material(
        color: Colors.transparent,
        animationDuration: const Duration(milliseconds: 300),
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        shape: _layerShape,
        child: widget.frontLayer,
      ),
    );
  }

  Widget _buildGestureDetector(BuildContext context, BoxConstraints constraints) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        if (_delegate.childHeight == _size) return;
        RenderBox box = context.findRenderObject();
        _dragOffset = box.globalToLocal(details.globalPosition).dy;
      },
      onVerticalDragUpdate: (details) {
        if (_delegate.childHeight == _size) return;
        _layerController.value = (details.globalPosition.dy - _delegate.diffHeight + _dragOffset + _size) /_delegate.childHeight;
      },
      onVerticalDragEnd: (details) {
        if (_delegate.childHeight == _size) return;
        if (_layerController.value != 1 && _layerController.value != 0) {
          if (details.primaryVelocity != 0) {
            _layerController.fling(velocity: details.primaryVelocity / _delegate.childHeight);
          } else {
            final double velocity = _layerController.value < 0.5 ? -1 : 1;
            _layerController.fling(velocity: velocity);
          }
        }
      },
    );
  }

  Widget _buildGestureDetectorContainer(BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _delegate.childHeight + _size),
      end: EdgeInsets.only(bottom: _size),
    ).animate(_layerController.view);
    return PaddingTransition(
      padding: layerAnimation,
      child: SizedBox(
        height: 32,
        child: LayoutBuilder(builder: _buildGestureDetector),
      ),
    );
  }

  Widget _buildFab(BuildContext context, BoxConstraints constraints) {
    Animation<EdgeInsets> layerAnimation = EdgeInsetsTween(
      begin: EdgeInsets.only(bottom: _delegate.childHeight + 28),
      end: EdgeInsets.only(bottom: _size - 28),
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
    return Material(
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
                    left: 16,
                    right: 16,
                    bottom: _size,
                  ),
                  child: widget.backLayer,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.close_menu,
                      progress: _layerController.view,
                    ),
                    onPressed: _delegate.childHeight == _size ? null : _toggleBackdropLayerVisibility,
                  ),
                  Expanded(
                    child: SizedBox(height: _size),
                  ),
                  if (widget.actions != null)
                    ...widget.actions,
                ],
              ),
            ),
            LayoutBuilder(builder: _buildFrontLayer),
            LayoutBuilder(builder: _buildGestureDetectorContainer),
            LayoutBuilder(builder: _buildFab),
          ],
        ),
    );
  }
}

class _SizeSavingDelegate extends SingleChildLayoutDelegate {
  Size parentSize = Size.square(0);
  Size childSize = Size.square(0);

  double get diffHeight => parentSize.height - childSize.height;

  double get childWidth => childSize.width;

  double get childHeight => childSize.height;

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    _SizeSavingDelegate old = oldDelegate as _SizeSavingDelegate;
    return old.childSize != childSize || old.parentSize != parentSize;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    this.parentSize = size;
    this.childSize = childSize;
    return Offset(0.0, diffHeight);
  }
}
