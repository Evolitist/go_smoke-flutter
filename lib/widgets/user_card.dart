import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/auth.dart';

const _code = <int>[2, 2, 3, 3, 0, 1, 0, 1];

class UserCard extends StatefulWidget {
  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> with TickerProviderStateMixin {
  final Auth _auth = Auth();
  AnimationController _fadeController;
  AnimationController _eeController;
  TextEditingController _inputController;
  bool _eeVertical = true;
  int _eeCounter = 0;
  String _photoUrl;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..addListener(() => setState(() {}));
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
    _inputController = TextEditingController();
    _auth.addCallback(() => setState(() {
          _fadeController.reverse();
          _photoUrl = _auth.currentUser?.photoUrl;
        }));
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

  void _phoneVerify(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter verification code'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            controller: _inputController,
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            FlatButton(
              child: Text('SEND'),
              onPressed: () {
                _auth.verifyPhone(_inputController.text);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _phoneSignIn(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter phone number'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.phone,
            controller: _inputController,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                _fadeController.reverse();
                Navigator.of(ctx).pop();
              },
            ),
            FlatButton(
              child: Text('VERIFY'),
              onPressed: () {
                _auth.startPhoneSignIn(_inputController.text, () {
                  Navigator.of(context).pop();
                });
                _inputController.text = '';
                Navigator.of(ctx).pop();
                _phoneVerify(context);
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPageContents(BuildContext context) {
    if (_auth.signedIn) {
      return <Widget>[
        Spacer(),
        Stack(
          children: <Widget>[
            Transform(
              transform: Matrix4.rotationX(
                  _eeVertical ? _eeController.value * pi : 0.0),
              alignment: Alignment.center,
              child: Transform(
                transform: Matrix4.rotationY(
                    _eeVertical ? 0.0 : _eeController.value * pi),
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 48.0,
                  backgroundImage: CachedNetworkImageProvider(_photoUrl ?? ''),
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
                                _eeController.animateTo(
                                  0.0,
                                  duration: Duration(milliseconds: 300),
                                ).whenComplete(() {
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
                                print('works.');
                              }
                              _eeController.animateTo(
                                0.0,
                                duration: Duration(milliseconds: 300),
                              ).whenComplete(() {
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
        ),
        SizedBox(height: 16.0),
        Text(
          _auth.currentUser.displayName ?? _auth.currentUser.phoneNumber,
          style: Theme.of(context).textTheme.title,
        ),
        Spacer(),
        Divider(height: 0.0),
        ListTile(
          leading: Icon(Icons.group),
          title: Text('Groups'),
          trailing: Transform.scale(
            scale: 0.67,
            child: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).iconTheme.color.withOpacity(0.54),
            ),
          ),
          onTap: () {},
        ),
      ];
    } else {
      return <Widget>[
        Spacer(),
        RaisedButton.icon(
          icon: Image.asset('icons/google_logo.png'),
          label: Text('Sign in with Google'),
          color: Colors.grey[50],
          textColor: Colors.black.withOpacity(0.54),
          onPressed: () {
            _auth.googleSignIn();
            _fadeController.forward();
          },
        ),
        SizedBox(
          height: 16.0,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: Divider(),
          ),
        ),
        RaisedButton.icon(
          icon: Icon(Icons.smartphone),
          label: Text('Sign in with phone'),
          onPressed: () {
            _phoneSignIn(context);
            _fadeController.forward();
          },
        ),
        Spacer(),
      ];
    }
  }

  Widget _buildPage(BuildContext context, BoxConstraints constraints) {
    double sz = min(constraints.biggest.width, constraints.biggest.height);
    return Container(
      width: sz,
      height: sz * 0.75,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildPageContents(context),
      ),
    );
  }

  Widget _buildProgress(BuildContext context, BoxConstraints constraints) {
    double sz = min(constraints.biggest.width, constraints.biggest.height);
    return Container(
      width: sz,
      height: sz * 0.75,
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 48.0, vertical: 4.0),
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: 1.0 - _fadeController.value,
            child: LayoutBuilder(builder: _buildPage),
          ),
          Opacity(
            opacity: _fadeController.value,
            child: LayoutBuilder(builder: _buildProgress),
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 0.0,
            end: 0.0,
            child: PopupMenuButton(
              itemBuilder: (ctx) {
                return <PopupMenuEntry>[
                  PopupMenuItem(
                    child: Text('Log out'),
                    value: 1,
                    enabled: _auth.signedIn,
                  ),
                ];
              },
              onSelected: (i) {
                if (i == 1) {
                  _eeCounter = 0;
                  _auth.signOut();
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
