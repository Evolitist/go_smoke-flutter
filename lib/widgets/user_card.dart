import 'dart:math';

import 'package:flutter/material.dart';

import '../a/a.dart';
import '../services/auth.dart';

class UserCard extends StatefulWidget {
  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> with TickerProviderStateMixin {
  final Auth _auth = Auth();
  AnimationController _fadeController;
  TextEditingController _inputController;
  String _photoUrl;
  String _displayName;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..addListener(() => setState(() {}));
    _inputController = TextEditingController();
    _auth.addCallback(() => setState(() {
          _fadeController.reverse();
          _photoUrl = _auth.currentUser?.photoUrl;
          _displayName = _auth.currentUser?.displayName;
        }));
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
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Enter phone number'),
              content: TextField(
                autofocus: true,
                keyboardType: TextInputType.phone,
                enabled: !_auth.inProgress,
                controller: _inputController,
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('CANCEL'),
                  onPressed: () {
                    _fadeController.reverse();
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: _auth.inProgress
                      ? SizedBox(
                          width: Theme.of(context).buttonTheme.height - 24.0,
                          height: Theme.of(context).buttonTheme.height - 24.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : Text('VERIFY'),
                  onPressed: _auth.inProgress
                      ? null
                      : () {
                          _auth.startPhoneSignIn(
                            phoneNumber: _inputController.text,
                            onCodeSent: () {
                              _inputController.text = '';
                              Navigator.of(context).pop();
                              _phoneVerify(context);
                            },
                            onSuccess: () {
                              Navigator.of(context).pop();
                            },
                            onError: () {
                              _fadeController.reverse();
                              Navigator.of(context).pop();
                            },
                          );
                          setState(() {});
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String newName;
        return Form(
          autovalidate: true,
          child: StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Edit profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: _auth.currentUser?.displayName,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (displayName) {
                      return displayName.isEmpty
                          ? 'Please enter your (nick)name'
                          : null;
                    },
                    onSaved: (value) {
                      newName = value;
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('CANCEL'),
                  onPressed: () {
                    Form.of(ctx).reset();
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: _auth.updating
                      ? SizedBox(
                          width: Theme.of(context).buttonTheme.height - 24.0,
                          height: Theme.of(context).buttonTheme.height - 24.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : Text('UPDATE'),
                  onPressed: _auth.updating
                      ? null
                      : () async {
                          if (Form.of(ctx).validate()) {
                            Form.of(ctx).save();
                            Future job = _auth.updateUserProfile(displayName: newName);
                            setDialogState(() {});
                            await job;
                            Navigator.of(context).pop();
                          }
                        },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  List<Widget> _buildPageContents(BuildContext context) {
    if (_auth.signedIn) {
      return <Widget>[
        Spacer(),
        UserAvatar(photoUrl: _photoUrl),
        SizedBox(height: 16.0),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Container()),
              Text(
                _displayName ?? _auth.currentUser.phoneNumber,
                style: Theme.of(context).textTheme.title,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.edit),
                    iconSize: 18.0,
                    onPressed: () {
                      _editProfile(context);
                    },
                  ),
                ),
              ),
            ],
          ),
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
