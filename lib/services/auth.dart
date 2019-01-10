import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthProvider { google, phone }

enum AuthState { none, inProgress, signedIn }

enum ProfileState { still, updating }

class Auth {
  static final Auth _singleton = Auth._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleAuth = GoogleSignIn();
  final ValueNotifier<FirebaseUser> _currentUser = ValueNotifier(null);
  final ValueNotifier<AuthState> _state = ValueNotifier(AuthState.none);
  final ValueNotifier<ProfileState> _profileState = ValueNotifier(ProfileState.still);
  String _verificationId;

  factory Auth() => _singleton;

  Auth._() {
    _auth.currentUser().then((user) => _currentUser.value = user);
  }

  FirebaseUser get currentUser => _currentUser.value;

  bool get signedIn => _currentUser.value != null;

  void addCallback(VoidCallback callback) => _currentUser.addListener(callback);

  bool get inProgress => _state.value == AuthState.inProgress;

  bool get updating => _profileState.value == ProfileState.updating;

  Future signOut() async {
    await _auth.signOut();
    _currentUser.value = null;
    _state.value = AuthState.none;
  }

  Future updateUserProfile({String displayName}) async {
    _profileState.value = ProfileState.updating;
    UserUpdateInfo updateInfo = UserUpdateInfo();
    updateInfo.displayName = displayName;
    await _currentUser.value?.updateProfile(updateInfo);
    await _currentUser.value?.reload();
    _profileState.value = ProfileState.still;
    _auth.currentUser().then((user) => _currentUser.value = user);
  }

  Future googleSignIn() async {
    _state.value = AuthState.inProgress;
    GoogleSignInAccount googleUser =
        await _googleAuth.signInSilently() ?? await _googleAuth.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    if (await _auth.currentUser() == null) {
      _currentUser.value = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } else {
      _currentUser.value = await _auth.linkWithGoogleCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }
    _state.value = AuthState.signedIn;
  }

  Future startPhoneSignIn({
    String phoneNumber,
    VoidCallback onCodeSent,
    VoidCallback onSuccess,
    VoidCallback onError,
  }) async {
    _state.value = AuthState.inProgress;
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (newUser) {
        _currentUser.value = newUser;
        _state.value = AuthState.signedIn;
        onSuccess();
      },
      verificationFailed: (exception) {
        print('${exception.code}: ${exception.message}');
        if (_state.value == AuthState.inProgress) {
          _state.value = AuthState.none;
          onError();
        }
      },
      codeSent: (vId, [force]) {
        _verificationId = vId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (vId) {},
    );
  }

  Future verifyPhone(String code) async {
    _auth.signInWithPhoneNumber(verificationId: _verificationId, smsCode: code);
  }
}
