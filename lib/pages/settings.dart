import 'package:flutter/material.dart';

import '../services/prefs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  final Prefs _prefs = Prefs();
  bool isDark;

  @override
  void initState() {
    super.initState();
    isDark = _prefs['isDark'] ?? false;
  }

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return GroupListTile(
          heading: 'INTERFACE',
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
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        titleSpacing: 24.0,
        centerTitle: true,
        elevation: 0.0,
        textTheme: Theme.of(context).textTheme,
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(itemBuilder: _buildListItem),
    );
  }
}

class GroupListTile extends StatelessWidget {
  final String heading;
  final List<Widget> children;

  GroupListTile({
    Key key,
    @required this.heading,
    @required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(children.length + 2, (index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16.0, 28.0, 16.0, 4.0),
            child: Text(
              heading,
              style: Theme.of(context).textTheme.overline.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          );
        } else if (index <= children.length) {
          return children[index - 1];
        } else if (index == children.length + 1) {
          return Divider(
            height: 0.0,
          );
        } else {
          return null;
        }
      }),
    );
  }
}
