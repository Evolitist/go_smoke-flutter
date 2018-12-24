import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatefulWidget {
  final Curve curve;
  final Duration duration;
  final double radius;
  final String photoUrl;
  final String displayName;
  final bool inProgress;

  const UserAvatar({
    Key key,
    this.radius: 24.0,
    this.photoUrl,
    this.displayName,
    this.inProgress: false,
    this.curve: Curves.easeInOut,
    this.duration: const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  _UserAvatarState createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar>
    with SingleTickerProviderStateMixin {
  String _lastUrl;
  AnimationController _controller;
  Tween<double> _photoScale = Tween(begin: 0.0, end: 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      upperBound: 1.0,
      lowerBound: 0.0,
      value: 1.0,
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inProgress && !oldWidget.inProgress) {
      _controller.animateTo(0.0, curve: widget.curve);
    } else if (!widget.inProgress && oldWidget.inProgress) {
      setState(() {
        _lastUrl = widget.photoUrl;
      });
      _controller.animateTo(1.0, curve: widget.curve);
    } else if (widget.photoUrl != oldWidget.photoUrl) {
      _controller.animateTo(0.5, curve: widget.curve).whenComplete(() {
        setState(() {
          _lastUrl = widget.photoUrl;
        });
        Future.delayed(Duration(milliseconds: 100), () {
          _controller.animateTo(1.0, curve: widget.curve);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ScaleTransition(
          scale: _photoScale.animate(
            CurvedAnimation(
              parent: _controller.view,
              curve: Interval(0.5, 1.0),
            ),
          ),
          child: CircleAvatar(
            backgroundImage:
                _lastUrl == null ? null : CachedNetworkImageProvider(_lastUrl),
            child: _lastUrl == null
                ? Icon(
                    Icons.person_outline,
                    size: widget.radius,
                    color: Theme.of(context).iconTheme.color,
                  )
                : null,
            radius: widget.radius,
          ),
        ),
        ScaleTransition(
          scale: _photoScale.animate(
            ReverseAnimation(
              CurvedAnimation(
                parent: _controller.view,
                curve: Interval(0.0, 0.5),
              ),
            ),
          ),
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}
