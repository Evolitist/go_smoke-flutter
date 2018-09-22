import 'package:flutter/material.dart';
import '../services/auth.dart';
import '../services/prefs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  final Prefs _prefs = Prefs();
  final Auth _auth = Auth();
  bool isDark;

  @override
  void initState() {
    super.initState();
    isDark = _prefs['isDark'] ?? false;
  }

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return Material(
          type: MaterialType.card,
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipOval(
                  child: CircleAvatar(
                    backgroundImage: _auth.signedIn
                        ? NetworkImage(_auth.currentUser.photoUrl)
                        : null,
                    child: _auth.signedIn
                        ? null
                        : LayoutBuilder(
                            builder: (ctx, size) {
                              return Icon(
                                Icons.person_outline,
                                size: size.biggest.width / 2.0,
                                color: Colors.grey[850],
                              );
                            },
                          ),
                    radius: 48.0,
                  ),
                ),
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
                              await _auth.signOut();
                              setState(() {});
                            }
                          : () async {
                              await _auth.googleSignIn();
                              setState(() {});
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case 1:
        return SizedBox(
          height: 8.0,
        );
      case 2:
        return Material(
          type: MaterialType.card,
          elevation: 2.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SwitchListTile(
                title: const Text("Dark theme"),
                value: isDark,
                onChanged: (value) {
                  _prefs['isDark'] = value;
                  setState(() {
                    isDark = value;
                  });
                },
              ),
            ],
          ),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[isDark ? 850 : 50],
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView.builder(itemBuilder: _buildListItem),
    );
  }
}
