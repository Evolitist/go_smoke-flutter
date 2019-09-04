import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final GoogleSignIn _googleAuth;
  final FirebaseAuth _firebaseAuth;
  final Firestore _firestore;

  UserRepository({GoogleSignIn googleAuth, FirebaseAuth firebaseAuth, Firestore firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuth = googleAuth ?? GoogleSignIn.standard(),
        _firestore = firestore ?? Firestore.instance;

  Future<FirebaseUser> signInWithGoogle() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    GoogleSignInAccount googleUser = await _googleAuth.signInSilently() ?? await _googleAuth.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    AuthCredential cred = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    if (user == null) {
      return _firebaseAuth.signInWithCredential(cred).then((r) => r.user);
    } else {
      return user.linkWithCredential(cred).then((r) => r.user);
    }
  }

  Future<FirebaseUser> signInWithPhone({Stream<String> data}) {
    String _vId;
    Completer<FirebaseUser> _user = Completer<FirebaseUser>();
    int i = 0;
    StreamSubscription dataSub;
    dataSub = data.listen((s) {
      if (i == 0) {
        ++i;
        _firebaseAuth.verifyPhoneNumber(
          phoneNumber: s,
          timeout: const Duration(milliseconds: 0),
          verificationCompleted: (cred) => _firebaseAuth.signInWithCredential(cred).then((r) {
            _user.complete(r.user);
            dataSub.cancel();
          }),
          verificationFailed: (error) {
            print(error.message);
            _user.completeError(error);
          },
          codeSent: (vId, [forceResend]) => _vId = vId,
          codeAutoRetrievalTimeout: (vId) => _vId = vId,
        ).catchError(print);
      } else if (i == 1) {
        AuthCredential cred = PhoneAuthProvider.getCredential(verificationId: _vId, smsCode: s);
        _firebaseAuth.signInWithCredential(cred).then((r) {
          _user.complete(r.user);
          dataSub.cancel();
        }, onError: print);
      }
    });
    return _user.future;
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<bool> isSignedIn() async {
    final currentUser = await _firebaseAuth.currentUser();
    return currentUser != null;
  }

  Future<FirebaseUser> getUser() => _firebaseAuth.currentUser();

  Future uploadAvatar(bool useCamera) async {
    /*if (!(await isSignedIn())) return;
    File image = await ImagePicker.pickImage(source: useCamera ? ImageSource.camera : ImageSource.gallery);
    if (image != null) {
      FirebaseUser user = await getUser();
      var snap = await _storage.ref()
          .child('users/${user.uid}/ava.${image.path.split('.').last}')
          .putFile(image)
          .onComplete;
      String url = await snap.ref.getDownloadURL();
      await user.updateProfile(UserUpdateInfo()..photoUrl = url);
      await _firestore.collection('users').document(user.uid).setData(
        {'ava_url': url},
        merge: true,
      );
    }*/
  }

  Future<FirebaseUser> updateName(String name) async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    await user.updateProfile(UserUpdateInfo()..displayName = name);
    await user.reload();
    await _firestore.collection('users').document(user.uid).setData(
      {'display_name': name},
      merge: true,
    );
    return _firebaseAuth.currentUser();
  }

  Future<FirebaseUser> updatePhone({Stream<String> data}) async {
    String _vId;
    Completer<FirebaseUser> _user = Completer<FirebaseUser>();
    int i = 0;
    StreamSubscription dataSub;
    dataSub = data.listen((s) {
      if (i == 0) {
        ++i;
        _firebaseAuth.verifyPhoneNumber(
          phoneNumber: s,
          timeout: const Duration(milliseconds: 0),
          verificationCompleted: (cred) async {
            (await _firebaseAuth.currentUser()).updatePhoneNumberCredential(cred).then((r) {
              _user.complete(_firebaseAuth.currentUser());
              dataSub.cancel();
            });
          },
          verificationFailed: (error) {
            print(error.message);
            _user.completeError(error);
          },
          codeSent: (vId, [forceResend]) => _vId = vId,
          codeAutoRetrievalTimeout: (vId) => _vId = vId,
        ).catchError(print);
      } else if (i == 1) {
        AuthCredential cred = PhoneAuthProvider.getCredential(verificationId: _vId, smsCode: s);
        _firebaseAuth.currentUser().then((u) {
          u.updatePhoneNumberCredential(cred).then((_) {
            _user.complete(_firebaseAuth.currentUser());
            dataSub.cancel();
          }, onError: print);
        }, onError: print);
      }
    });
    return _user.future;
  }
}