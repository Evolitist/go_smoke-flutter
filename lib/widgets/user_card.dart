import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/auth.dart';

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
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
                radius: 48.0,
                backgroundImage: _auth.signedIn
                    ? CachedNetworkImageProvider(_auth.currentUser.photoUrl)
                    : null,
                child: _auth.signedIn
                    ? null
                    : LayoutBuilder(
                        builder: (ctx, size) => Icon(
                              Icons.person_outline,
                              size: size.biggest.width / 2.0,
                              color: Colors.grey[850],
                            ),
                      )),
            SizedBox(width: 16.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _auth.currentUser?.displayName ?? '',
                  style: Theme.of(context).textTheme.title,
                ),
                OutlineButton(
                  child: Text(_auth.signedIn ? 'SIGN OUT' : 'SIGN IN'),
                  onPressed: _auth.signedIn
                      ? () async {
                          Future task = _auth.signOut();
                          setState(() {});
                          await task;
                          setState(() {});
                        }
                      : () async {
                          Future task = _auth.googleSignIn();
                          setState(() {});
                          await task;
                          setState(() {});
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
