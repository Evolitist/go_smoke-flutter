import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

final Function eq = const ListEquality().equals;

enum AuthProvider { google, phone }

enum AuthState { none, inProgress, signedIn }

enum ProfileState { still, updating }

class AuthManager extends StatefulWidget {
  AuthManager({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  AuthManagerState createState() => AuthManagerState();

  static AuthManagerState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(AuthModel) as AuthModel)
        .controller;
  }
}

class AuthManagerState extends State<AuthManager> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;
  final GoogleSignIn _googleAuth = GoogleSignIn();
  final TextEditingController _inputController = TextEditingController();
  FirebaseUser user;
  List<Group> groups = [];
  AuthState authState = AuthState.none;
  AuthProvider authProvider;
  ProfileState profileState = ProfileState.still;
  String _verificationId;

  bool get inProgress => authState == AuthState.inProgress;

  bool get updating => profileState == ProfileState.updating;

  @override
  void initState() {
    super.initState();
    _auth.currentUser().then((currentUser) {
      setState(() {
        user = currentUser;
      });
      checkGroups();
    });
  }

  List<DocumentReference> _groupsToRefs(List<Group> groups) {
    return groups
        .map((group) => _db.collection('groups').document(group.uid))
        .toList();
  }



  Future checkGroups() async {
    List<Group> groups = [];
    if (user == null) return;
    DocumentSnapshot doc =
        await _db.collection('users').document(user.uid).get();
    if (doc.exists) {
      List<DocumentReference> newGroups = List.castFrom(doc.data['groups']);
      for (var doc in newGroups) {
        DocumentSnapshot gDoc = await doc.get();
        groups.add(Group(
          gDoc.documentID,
          gDoc.data['name'],
          gDoc.data['creator'],
        ));
      }
    } else {
      doc.reference.setData({'groups': _groupsToRefs(groups)});
    }
    setState(() {
      this.groups = groups;
    });
  }

  Future _createGroup({@required String name, VoidCallback onSuccess}) async {
    //TODO: limit group creations per user
    DocumentReference groupRef = _db.collection('groups').document()
      ..setData({'name': name, 'creator': user.uid});
    List<Group> groups = List.of(this.groups)
      ..add(Group(groupRef.documentID, name, user.uid));
    await _db
        .collection('users')
        .document(user.uid)
        .setData({'groups': _groupsToRefs(groups)});
    setState(() {
      this.groups = groups;
    });
  }

  Future _deleteGroup({@required Group group}) async {
    DocumentReference groupRef = _db.collection('groups').document(group.uid);
    await groupRef.delete();
    List<Group> groups = List.of(this.groups)..remove(group);
    QuerySnapshot snap = await _db
        .collection('users')
        .where('groups', arrayContains: groupRef)
        .getDocuments();
    snap.documents.forEach((doc) {
      doc.reference.setData(doc.data
        ..update('groups', (list) {
          List<DocumentReference> old = List.castFrom(list);
          return List.of(old)..remove(groupRef);
        }));
    });
    setState(() {
      this.groups = groups;
    });
  }

  Future signOut() async {
    await _auth.signOut();
    setState(() {
      user = null;
      authState = AuthState.none;
      groups = [];
    });
  }

  Future _updateUserProfile({String displayName}) async {
    setState(() {
      profileState = ProfileState.updating;
    });
    UserUpdateInfo updateInfo = UserUpdateInfo();
    updateInfo.displayName = displayName;
    await user?.updateProfile(updateInfo);
    await user?.reload();
    _auth.currentUser().then((user) {
      setState(() {
        profileState = ProfileState.still;
        this.user = user;
      });
    });
  }

  Future googleSignIn() async {
    setState(() {
      authProvider = AuthProvider.google;
      authState = AuthState.inProgress;
    });
    FirebaseUser user = await _auth.currentUser();
    GoogleSignInAccount googleUser =
        await _googleAuth.signInSilently() ?? await _googleAuth.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    if (user == null) {
      user = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } else {
      user = await _auth.linkWithGoogleCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }
    setState(() {
      this.user = user;
      authState = AuthState.signedIn;
      authProvider = null;
    });
    checkGroups();
  }

  Future _startPhoneSignIn({
    String phoneNumber,
    VoidCallback onCodeSent,
    VoidCallback onSuccess,
    VoidCallback onError,
  }) async {
    setState(() {
      authProvider = AuthProvider.phone;
      authState = AuthState.inProgress;
    });
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (newUser) {
        setState(() {
          user = newUser;
          authState = AuthState.signedIn;
          authProvider = null;
        });
        checkGroups();
        onSuccess();
      },
      verificationFailed: (exception) {
        print('${exception.code}: ${exception.message}');
        if (authState == AuthState.inProgress) {
          setState(() {
            authState = AuthState.none;
            authProvider = null;
          });
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

  Future _verifyPhone(String code) async {
    _auth.signInWithPhoneNumber(verificationId: _verificationId, smsCode: code);
  }

  void createGroup(BuildContext context) {
    _inputController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter new group name'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.text,
            autocorrect: false,
            controller: _inputController,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            FlatButton(
              child: Text('CREATE'),
              onPressed: () {
                _createGroup(
                  name: _inputController.text,
                  onSuccess: () => setState(() {}),
                );
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void inviteToGroup(BuildContext context, Group group) async {
    //TODO: allow generating per-user invite links
    var params = DynamicLinkParameters(
      domain: 'gsmk.page.link',
      link: Uri.parse(
          'https://evolitist.github.io/gosmoke/join?gid=${group.uid}'),
      androidParameters: AndroidParameters(
        packageName: 'com.evolitist.gosmoke',
      ),
    );
    var link = await params.buildShortLink();
    Clipboard.setData(ClipboardData(text: link.shortUrl.toString()));
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard!'),
      ),
    );
  }

  void joinGroup(Uri link) async {
    if (link == null) return;
    String id = link.queryParameters['gid'];
    if (id == null) return;
    DocumentReference groupRef = _db.collection('groups').document(id);
    DocumentSnapshot doc = await groupRef.get();
    if (!doc.exists) return;
    if (doc.data['creator'] == user.uid) return;
    List<Group> groups = List.of(this.groups);
    if (groups.any((g) => g.uid == groupRef.documentID)) return;
    groups.add(Group(
      groupRef.documentID,
      doc.data['name'],
      doc.data['creator'],
    ));
    await _db.collection('users').document(user.uid).setData({
      'groups': _groupsToRefs(groups),
    });
    setState(() {
      this.groups = groups;
    });
  }

  void leaveGroup(Group group) async {
    if (group == null) return;
    List<Group> groups = List.of(this.groups);
    if (!groups.contains(group)) return;
    groups.remove(group);
    await _db.collection('users').document(user.uid).setData({
      'groups': _groupsToRefs(groups),
    });
    setState(() {
      this.groups = groups;
    });
  }

  void deleteGroup(BuildContext context, Group group,
      {VoidCallback onSuccess}) {
    bool deleting = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text(
                'Are you sure you want to delete this group? This action cannot be undone!'),
            actions: <Widget>[
              FlatButton(
                child: Text('CANCEL'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              FlatButton(
                child: deleting
                    ? SizedBox(
                        width: Theme.of(context).buttonTheme.height - 24.0,
                        height: Theme.of(context).buttonTheme.height - 24.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : Text('DELETE'),
                onPressed: deleting
                    ? null
                    : () async {
                        setDialogState(() => deleting = true);
                        await _deleteGroup(group: group);
                        Navigator.of(ctx).pop();
                      },
              ),
            ],
          );
        });
      },
    );
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
                _verifyPhone(_inputController.text);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void phoneSignIn(BuildContext context) {
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
                enabled: !inProgress,
                controller: _inputController,
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: inProgress
                      ? SizedBox(
                          width: Theme.of(context).buttonTheme.height - 24.0,
                          height: Theme.of(context).buttonTheme.height - 24.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : Text('VERIFY'),
                  onPressed: inProgress
                      ? null
                      : () {
                          _startPhoneSignIn(
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
                              Navigator.of(context).pop();
                            },
                          );
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void editProfile(BuildContext context) {
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
                    initialValue: user?.displayName,
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
                  child: updating
                      ? SizedBox(
                          width: Theme.of(context).buttonTheme.height - 24.0,
                          height: Theme.of(context).buttonTheme.height - 24.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : Text('UPDATE'),
                  onPressed: updating
                      ? null
                      : () async {
                          if (Form.of(ctx).validate()) {
                            Form.of(ctx).save();
                            Future job =
                                _updateUserProfile(displayName: newName);
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

  @override
  Widget build(BuildContext context) {
    return AuthModel(
      controller: this,
      user: user,
      groups: groups,
      authState: authState,
      authProvider: authProvider,
      profileState: profileState,
      child: widget.child,
    );
  }
}

class AuthModel extends InheritedModel<String> {
  AuthModel({
    Key key,
    this.controller,
    this.user,
    this.groups: const <Group>[],
    this.authState: AuthState.none,
    this.authProvider,
    this.profileState: ProfileState.still,
    Widget child,
  }) : super(key: key, child: child);

  final AuthManagerState controller;
  final FirebaseUser user;
  final List<Group> groups;
  final AuthState authState;
  final AuthProvider authProvider;
  final ProfileState profileState;

  bool get signedIn => user != null;

  bool get inProgress => authState == AuthState.inProgress;

  bool get updating => profileState == ProfileState.updating;

  @override
  bool isSupportedAspect(Object aspect) {
    return aspect == 'user' ||
        aspect == 'groups' ||
        aspect == 'authState' ||
        aspect == 'authProvider' ||
        aspect == 'profileState';
  }

  @override
  bool updateShouldNotify(AuthModel old) {
    return user != old.user ||
        groups.length != old.groups.length ||
        authState != old.authState ||
        authProvider != old.authProvider ||
        profileState != old.profileState;
  }

  @override
  bool updateShouldNotifyDependent(AuthModel old, Set<String> deps) {
    return (user != old.user && deps.contains('user')) ||
        (groups.length != old.groups.length && deps.contains('groups')) ||
        (authState != old.authState && deps.contains('authState')) ||
        (authProvider != old.authProvider && deps.contains('authProvider')) ||
        (profileState != old.profileState && deps.contains('profileState'));
  }

  static AuthModel of(BuildContext context, {String aspect}) {
    return InheritedModel.inheritFrom<AuthModel>(context, aspect: aspect);
  }
}

@immutable
class Group {
  const Group(this.uid, this.name, this.creator)
      : assert(uid != null),
        assert(name != null),
        assert(creator != null);

  final String uid;
  final String name;
  final String creator;
}
