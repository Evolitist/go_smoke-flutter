import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  static final Auth _singleton = Auth._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleAuth = GoogleSignIn();
  final ValueNotifier<FirebaseUser> _currentUser = ValueNotifier(null);

  factory Auth() => _singleton;

  Auth._() {
    _auth.currentUser().then((user) => _currentUser.value = user);
  }

  FirebaseUser get currentUser => _currentUser.value;

  bool get signedIn => _currentUser.value != null;

  void addCallback(VoidCallback callback) => _currentUser.addListener(callback);

  Future signOut() async {
    await _auth.signOut();
    _currentUser.value = null;
  }

  Future googleSignIn() async {
    GoogleSignInAccount googleUser =
        await _googleAuth.signInSilently() ?? await _googleAuth.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    if (await _auth.currentUser() == null) {
      _currentUser.value = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('signed in ' + _currentUser.value.displayName);
    } else {
      _currentUser.value = await _auth.linkWithGoogleCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('linked Google to ' + _currentUser.value.displayName);
    }
  }
}
