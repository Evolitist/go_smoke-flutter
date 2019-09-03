import 'package:flutter/material.dart';

import '../a/b.dart';
import '../services/prefs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  PrefsModel _model;

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return GroupListTile(
          heading: 'INTERFACE',
          children: <Widget>[
            SwitchListTile(
              title: const Text('Dark theme'),
              value: _model.get('isDark', false),
              onChanged: (value) => _model.set('isDark', value),
            ),
          ],
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _model = PrefsModel.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        titleSpacing: 24,
        centerTitle: true,
        elevation: 0,
        textTheme: Theme.of(context).textTheme,
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).canvasColor,
      ),
      body: SliverEEContainer(
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(_buildListItem),
        ),
      ),
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
            padding: EdgeInsets.fromLTRB(16, 28, 16, 4),
            child: Text(
              heading,
              style: Theme.of(context).textTheme.overline.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else if (index <= children.length) {
          return children[index - 1];
        } else if (index == children.length + 1) {
          return const Divider(height: 0);
        } else {
          return null;
        }
      }),
    );
  }
}
