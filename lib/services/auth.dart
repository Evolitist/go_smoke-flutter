import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  static final Auth _singleton = Auth._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleAuth = GoogleSignIn();
  FirebaseUser _currentUser;

  factory Auth() => _singleton;

  Auth._() {
    _auth.currentUser().then((user) => _currentUser = user);
  }

  FirebaseUser get currentUser => _currentUser;

  Future signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Future googleSignIn() async {
    GoogleSignInAccount googleUser =
        await (_googleAuth.signInSilently() ?? _googleAuth.signIn());
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    if (await _auth.currentUser() == null) {
      _currentUser = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('signed in ' + _currentUser.displayName);
    } else {
      _currentUser = await _auth.linkWithGoogleCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('linked Google to ' + _currentUser.displayName);
    }
  }
}
