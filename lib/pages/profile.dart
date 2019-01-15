import 'package:flutter/material.dart';

import '../a/a.dart';
import '../services/auth.dart';

const _tabs = ['GROUPS', 'MANAGE'];

class ProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthManagerState _authManager;
  FirebaseUser _currentUser;
  List<Group> _groups;

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
          expandedHeight: signedIn
              ? 176.0 + kTextTabBarHeight
              : null,
          flexibleSpace: Builder(
            builder: (ctx) {
              FlexibleSpaceBarSettings set =
                  ctx.inheritFromWidgetOfExactType(FlexibleSpaceBarSettings);
              return FlexibleSpaceBar(
                background: SafeArea(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 16.0,
                      ),
                      UserAvatar(
                          photoUrl: _currentUser?.photoUrl ??
                              ''),
                    ],
                  ),
                ),
                title: Padding(
                  padding: signedIn
                      ? EdgeInsets.only(
                          bottom: (kTextTabBarHeight / 1.5) *
                              (1.0 +
                                  (1.0 -
                                          (set.currentExtent - set.minExtent) /
                                              (set.maxExtent - set.minExtent)) *
                                      0.5),
                        )
                      : EdgeInsets.zero,
                  child: Row(
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
                ),
                centerTitle: true,
              );
            },
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
          bottom: signedIn
              ? TabBar(
                  labelColor: Theme.of(context).textTheme.title.color,
                  tabs: _tabs.map((s) => Tab(text: s)).toList(),
                )
              : null,
          pinned: true,
        ),
      ),
    ];
  }

  Widget _buildContent(BuildContext context) {
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    _authManager = AuthManager.of(context);
    _currentUser = AuthModel.of(context, aspect: 'user').user;
    _groups = AuthModel.of(context, aspect: 'groups').groups;
    return Scaffold(
      body: DefaultTabController(
        length: _tabs.length,
        child: NestedScrollView(
          headerSliverBuilder: _buildHeader,
          body: signedIn
              ? TabBarView(
                  children: _tabs.map((name) {
                    if (name == 'MANAGE') return Container();
                    return Builder(
                      builder: (ctx) {
                        return ScrollConfiguration(
                          behavior: NoOverscrollBehavior(),
                          child: CustomScrollView(
                            slivers: <Widget>[
                              SliverOverlapInjector(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(ctx),
                              ),
                              SliverList(
                                delegate: SliverChildListDelegate(
                                  _groups.map((g) {
                                    return ListTile(
                                      title: Text(g.name),
                                      onTap: () {},
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                )
              : _buildContent(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'AnotherTag',
        child: Icon(Icons.add),
        onPressed: () {
          _authManager.createGroup(context);
        },
      ),
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
        AuthModel.of(context, aspect: 'authState').authState ==
            AuthState.inProgress;
    bool correct =
        AuthModel.of(context, aspect: 'authProvider').authProvider ==
            AuthProvider.google;
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
        AuthModel.of(context, aspect: 'authState').authState ==
            AuthState.inProgress;
    bool correct =
        AuthModel.of(context, aspect: 'authProvider').authProvider ==
            AuthProvider.phone;
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
