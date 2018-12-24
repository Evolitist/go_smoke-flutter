import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../widgets/user_avatar.dart';

class UserCard extends StatefulWidget {
  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  final Auth _auth = Auth();

  @override
  void initState() {
    super.initState();
    _auth.addCallback(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FractionallySizedBox(
        widthFactor: 2.0 / 3.0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              UserAvatar(
                radius: 48.0,
                photoUrl: _auth.currentUser?.photoUrl,
                inProgress: _auth.inProgress,
              ),
              SizedBox(height: 16.0),
              Text(
                _auth.currentUser?.displayName ?? '',
                style: Theme.of(context).textTheme.title,
              ),
              SizedBox(height: 16.0),
              RaisedButton(
                child: Text(_auth.inProgress
                    ? '...'
                    : (_auth.signedIn ? 'SIGN OUT' : 'SIGN IN')),
                shape: StadiumBorder(),
                onPressed: _auth.inProgress
                    ? null
                    : (_auth.signedIn
                    ? () async {
                  _auth.signOut();
                  setState(() {});
                }
                    : () async {
                  Future task = _auth.googleSignIn();
                  setState(() {});
                  await task;
                }),
              ),
            ],
          ),
        ),
      )
    );
  }
}
