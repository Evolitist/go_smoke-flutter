import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../a/a.dart';
import '../services/auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  PageController _pager = PageController();
  AuthManagerState _authManager;
  FirebaseUser _currentUser;
  List<Group> _groups;
  int _currentPage = 0;

  bool get signedIn => _currentUser != null;

  List<Widget> _buildHeader(BuildContext context, bool isScrolled) {
    return <Widget>[
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        child: SliverAppBar(
          backgroundColor: Theme.of(context).canvasColor,
          iconTheme: Theme.of(context).iconTheme,
          textTheme: Theme.of(context).textTheme,
          forceElevated: isScrolled,
          expandedHeight: signedIn ? 176.0 : null,
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 16.0,
                  ),
                  UserAvatar(photoUrl: _currentUser?.photoUrl ?? ''),
                ],
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: Container()),
                Text(
                  _currentUser?.displayName ??
                      _currentUser?.phoneNumber ??
                      'Welcome',
                  style: Theme.of(context).textTheme.title,
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomLeft,
                    padding: EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 1.0),
                    child: signedIn
                        ? InkResponse(
                            onTap: () {
                              _authManager.editProfile(context);
                            },
                            highlightColor: Colors.transparent,
                            child: Padding(
                              padding: EdgeInsets.all(1.0),
                              child: Icon(
                                Icons.edit,
                                size: 18.0,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                            radius: 16.0,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: signedIn
                  ? () {
                      _authManager.signOut();
                    }
                  : null,
            ),
          ],
          bottom: PreferredSize(
            child: Divider(height: 0.0),
            preferredSize: Size.fromHeight(1.0),
          ),
          pinned: true,
        ),
      ),
    ];
  }

  ListTile _createGroupTile(BuildContext ctx, Group group) {
    bool admin = group.creator == _currentUser.uid;
    return ListTile(
      leading: admin ? Icon(Icons.star) : Icon(Icons.person),
      title: Text(group.name),
      trailing: PopupMenuButton(
        itemBuilder: (ctx) {
          if (admin) {
            return <PopupMenuEntry>[
              PopupMenuItem(child: Text('Invite'), value: 0),
              PopupMenuDivider(),
              PopupMenuItem(child: Text('Delete'), value: 1),
            ];
          } else {
            return <PopupMenuEntry>[
              PopupMenuItem(child: Text('Leave'), value: 2),
            ];
          }
        },
        onSelected: (i) {
          switch (i) {
            case 0:
              _authManager.inviteToGroup(ctx, group);
              break;
            case 1:
              _authManager.deleteGroup(ctx, group);
              break;
            case 2:
              _authManager.leaveGroup(group);
              break;
          }
        },
      ),
      onTap: () {
        showDialog(
          context: ctx,
          builder: (ctx) {
            return AlertDialog(
              title: Text('Members'),
              content: FutureBuilder<QuerySnapshot>(
                future: Firestore.instance.collection('users').where('groups', arrayContains: group.uid).getDocuments(),
                builder: (ctx, snap) {
                  if (snap.hasData) {
                    return Container(
                      height: 100,
                      width: 100,
                      child: ListView(
                        children: <Widget>[
                          for (var s in snap.data.documents)
                            ListTile(
                              title: Text(s.documentID),
                            ),
                        ],
                      ),
                    );
                  }
                  return Container();
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _authManager = AuthManager.of(context);
    _currentUser = AuthModel.of(context, aspect: 'user');
    _groups = List.castFrom(AuthModel.of(context, aspect: 'groups'));
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: _buildHeader,
        body: signedIn
            ? PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: _pager,
                children: [
                  Builder(
                    builder: (ctx) {
                      return ScrollConfiguration(
                        behavior: ScrollBehavior(),
                        child: CustomScrollView(
                          slivers: <Widget>[
                            SliverOverlapInjector(
                              handle: NestedScrollView
                                  .sliverOverlapAbsorberHandleFor(ctx),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _createGroupTile(ctx, _groups[i]),
                                childCount: _groups.length,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(),
                ],
              )
            : Column(
                children: <Widget>[
                  Spacer(),
                  _GoogleLoginButton(authManager: _authManager),
                  SizedBox(
                    height: 16.0,
                    child: FractionallySizedBox(
                      widthFactor: 0.4,
                      child: Divider(),
                    ),
                  ),
                  _PhoneLoginButton(authManager: _authManager),
                  Spacer(),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            title: Text('Groups'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Manage'),
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentPage = index;
          });
          _pager.animateToPage(
            _currentPage,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
      floatingActionButton: _currentPage == 0
          ? FloatingActionButton(
              heroTag: null,
              child: Icon(Icons.add),
              onPressed: () {
                _authManager.createGroup(context);
              },
            )
          : null,
    );
  }
}

class _GoogleLoginButton extends StatefulWidget {
  _GoogleLoginButton({
    Key key,
    this.authManager,
  }) : super(key: key);

  final AuthManagerState authManager;

  @override
  State<StatefulWidget> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<_GoogleLoginButton> {
  @override
  Widget build(BuildContext context) {
    bool inProgress =
        AuthModel.of(context, aspect: 'authState') == AuthState.inProgress;
    bool correct =
        AuthModel.of(context, aspect: 'authProvider') == AuthProvider.google;
    return RaisedButton.icon(
      icon: Icon(Icons.cloud),
      label: correct
          ? SizedBox(
              width: Theme.of(context).buttonTheme.height - 24.0,
              height: Theme.of(context).buttonTheme.height - 24.0,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            )
          : Text('Sign in with Google'),
      color: Colors.grey[50],
      textColor: Colors.black.withOpacity(0.54),
      onPressed: inProgress
          ? null
          : () {
              widget.authManager.googleSignIn();
            },
    );
  }
}

class _PhoneLoginButton extends StatefulWidget {
  _PhoneLoginButton({
    Key key,
    this.authManager,
  }) : super(key: key);

  final AuthManagerState authManager;

  @override
  State<StatefulWidget> createState() => _PhoneLoginButtonState();
}

class _PhoneLoginButtonState extends State<_PhoneLoginButton> {
  @override
  Widget build(BuildContext context) {
    bool inProgress =
        AuthModel.of(context, aspect: 'authState') == AuthState.inProgress;
    bool correct =
        AuthModel.of(context, aspect: 'authProvider') == AuthProvider.phone;
    return RaisedButton.icon(
      icon: Icon(Icons.smartphone),
      label: correct
          ? SizedBox(
              width: Theme.of(context).buttonTheme.height - 24.0,
              height: Theme.of(context).buttonTheme.height - 24.0,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            )
          : Text('Sign in with phone'),
      onPressed: inProgress
          ? null
          : () {
              widget.authManager.phoneSignIn(context);
            },
    );
  }
}

class NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
