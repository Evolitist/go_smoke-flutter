import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const _code = <int>[2, 2, 3, 3, 0, 1, 0, 1];

class UserAvatar extends StatefulWidget {
  final String photoUrl;

  UserAvatar({
    Key key,
    String photoUrl,
  })  : this.photoUrl = photoUrl ?? '',
        super(key: key);

  @override
  State<StatefulWidget> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar>
    with SingleTickerProviderStateMixin {
  AnimationController _eeController;
  bool _eeVertical = true;
  int _eeCounter = 0;

  @override
  void initState() {
    super.initState();
    _eeController = AnimationController(
      lowerBound: -100.0,
      value: 0.0,
      upperBound: 100.0,
      animationBehavior: AnimationBehavior.preserve,
      vsync: this,
    )..addListener(() {
        if (_eeController.value.abs() == 100.0) {
          _checkEE(_eeVertical, _eeController.value);
        }
        setState(() {});
      });
  }

  void _checkEE(bool a, double d) {
    if (_eeCounter >= _code.length) return;
    _eeController.value = 0.0;
    int state = ((a ? 1 : 0) << 1) | (d > 0 ? 1 : 0);
    if (state == _code[_eeCounter]) {
      _eeCounter++;
      if (_eeCounter == _code.length) {
        _eeController.fling(velocity: -1.0);
        setState(() {});
      }
    } else {
      _eeCounter = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Transform(
          transform:
              Matrix4.rotationX(_eeVertical ? _eeController.value * pi : 0.0),
          alignment: Alignment.center,
          child: Transform(
            transform:
                Matrix4.rotationY(_eeVertical ? 0.0 : _eeController.value * pi),
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 48.0,
              backgroundImage:
                  CachedNetworkImageProvider(widget.photoUrl ?? ''),
            ),
          ),
        ),
        Transform(
          transform: Matrix4.rotationY(_eeCounter >= _code.length
              ? (-_eeController.value - 99.5).clamp(0, 0.5) * pi + pi * 1.5
              : pi / 2.0),
          alignment: Alignment.center,
          child: Material(
            shape: CircleBorder(),
            color: Colors.black.withOpacity(0.5),
            child: SizedBox(
              width: 96.0,
              height: 96.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Material(
                    shape: CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    elevation: 4.0,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      alignment: Alignment.center,
                      child: InkResponse(
                        child: Text('A'),
                        radius: 16.0,
                        onTap: () {
                          if (_eeCounter == _code.length) {
                            setState(() {
                              _eeCounter++;
                            });
                          } else {
                            _eeController
                                .animateTo(
                              0.0,
                              duration: Duration(milliseconds: 300),
                            )
                                .whenComplete(() {
                              setState(() {
                                _eeCounter = 0;
                              });
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  VerticalDivider(width: 0.0),
                  Material(
                    shape: CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    elevation: 4.0,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      alignment: Alignment.center,
                      child: InkResponse(
                        child: Text('B'),
                        radius: 16.0,
                        onTap: () {
                          if (_eeCounter == _code.length + 1) {
                            //TODO: handle successful activation
                          }
                          _eeController
                              .animateTo(
                            0.0,
                            duration: Duration(milliseconds: 300),
                          )
                              .whenComplete(() {
                            setState(() {
                              _eeCounter = 0;
                            });
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: _eeCounter >= _code.length
                ? HitTestBehavior.translucent
                : HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              double velocity = details.velocity.pixelsPerSecond.dx /
                  min(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height);
              if (velocity.abs() > 10) {
                setState(() {
                  _eeVertical = false;
                });
                _eeController.fling(velocity: velocity * 0.0001);
              }
            },
            onVerticalDragEnd: (details) {
              double velocity = details.velocity.pixelsPerSecond.dy /
                  min(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height);
              if (velocity.abs() > 10) {
                setState(() {
                  _eeVertical = true;
                });
                _eeController.fling(velocity: velocity * 0.0001);
              }
            },
          ),
        ),
      ],
    );
  }
}
