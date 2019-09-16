import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:go_smoke/model/group.dart';
import 'package:go_smoke/model/user.dart';

class UserRepository {
  final GoogleSignIn _googleAuth;
  final FirebaseAuth _auth;
  final Firestore _db;
  final CloudFunctions _funcs;

  UserRepository({
    GoogleSignIn googleAuth,
    FirebaseAuth firebaseAuth,
    Firestore firestore,
    CloudFunctions cloudFunctions,
  }) :  _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleAuth = googleAuth ?? GoogleSignIn.standard(),
        _db = firestore ?? Firestore.instance,
        _funcs = cloudFunctions ?? CloudFunctions.instance;

  Future<User> googleSighIn() async => _requireData(await _signInWithGoogle());

  Future<FirebaseUser> _signInWithGoogle() async {
    FirebaseUser user = await _auth.currentUser();
    GoogleSignInAccount googleUser = await _googleAuth.signInSilently() ?? await _googleAuth.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    AuthCredential cred = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return user?.linkWithCredential(cred)?.then((r) => r.user) ?? _auth.signInWithCredential(cred).then((r) => r.user);
  }

  Future<User> phoneSighIn(Stream<String> data) async => _requireData(await _signInWithPhone(data));

  Future<FirebaseUser> _signInWithPhone(Stream<String> data) {
    if (data.isBroadcast) throw ArgumentError('Stream passed to this method must not be broadcast');
    String _vId;
    Completer<FirebaseUser> _user = Completer<FirebaseUser>();
    int i = 0;
    StreamSubscription dataSub;
    dataSub = data.listen((s) {
      if (i == 0) {
        ++i;
        _auth.verifyPhoneNumber(
          phoneNumber: s,
          timeout: const Duration(milliseconds: 0),
          verificationCompleted: (cred) => _auth.signInWithCredential(cred).then((r) {
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
        _auth.signInWithCredential(cred).then((r) {
          _user.complete(r.user);
          dataSub.cancel();
        }, onError: print);
      }
    });
    return _user.future;
  }

  User _requireData(FirebaseUser user) {
    return User(uid: user.uid, displayName: user.displayName ?? 'Anonymous', photoUrl: user.photoUrl);
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> get isSignedIn async => await _auth.currentUser() != null;

  Future<User> get currentUser async => _auth.currentUser().then((u) => User(
    uid: u.uid,
    displayName: u.displayName,
    photoUrl: u.photoUrl,
  ));

  Future uploadAvatar(bool useCamera) async {
    //TODO: implement
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

  Future<User> updateName(String name) async {
    FirebaseUser user = await _auth.currentUser();
    await user.updateProfile(UserUpdateInfo()..displayName = name);
    await user.reload();
    await _db.collection('u').document(user.uid).setData(
      {'n': name},
      merge: true,
    );
    return currentUser;
  }

  Future<void> updatePhone({Stream<String> data}) async {
    if (data.isBroadcast) throw ArgumentError('Stream passed to this method must not be broadcast');
    String _vId;
    Completer<FirebaseUser> _user = Completer<FirebaseUser>();
    int i = 0;
    StreamSubscription dataSub;
    dataSub = data.listen((s) {
      if (i == 0) {
        ++i;
        _auth.verifyPhoneNumber(
          phoneNumber: s,
          timeout: const Duration(milliseconds: 0),
          verificationCompleted: (cred) => _auth.currentUser().then((u) {
            u.updatePhoneNumberCredential(cred).then((_) {
              _user.complete(_auth.currentUser());
              dataSub.cancel();
            }, onError: print);
          }, onError: print),
          verificationFailed: (error) {
            print(error.message);
            _user.completeError(error);
          },
          codeSent: (vId, [forceResend]) => _vId = vId,
          codeAutoRetrievalTimeout: (vId) => _vId = vId,
        ).catchError(print);
      } else if (i == 1) {
        AuthCredential cred = PhoneAuthProvider.getCredential(verificationId: _vId, smsCode: s);
        _auth.currentUser().then((u) {
          u.updatePhoneNumberCredential(cred).then((_) {
            _user.complete(_auth.currentUser());
            dataSub.cancel();
          }, onError: print);
        }, onError: print);
      }
    });
    await _user.future;
  }

  /*Future<Group> createGroup(String name, double lat, double lng) async {
    //TODO: limit group creations per user
    DocumentReference groupRef = _db.collection('g').document()
      ..setData({'n': name, 'l': [lat, lng], 'c': _user.uid});
    List<Group> groups = List.of(_groups)..add(Group.raw(groupRef.documentID, name, location, _user.uid));
    await _db
        .collection('u')
        .document(_user.uid)
        .setData({'groups': _groupsToRefs(groups)});
  }*/

  Future<String> inviteToGroup(Group group) async {
    //TODO: allow generating per-user invite links
    final link = await DynamicLinkParameters(
      uriPrefix: 'https://gsmk.page.link',
      link: Uri.parse('https://evolitist.github.io/gosmoke/join?gid=${group.uid}'),
      androidParameters: AndroidParameters(
        packageName: 'com.evolitist.gosmoke',
      ),
    ).buildShortLink();
    return link.shortUrl.toString();
  }
}