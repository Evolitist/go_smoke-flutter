import 'package:flutter/material.dart';
import 'package:location/location.dart';

import 'backdrop.dart';
import 'olc.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
        accentColor: Colors.orangeAccent[400]
      ),
      home: Material(
        elevation: 0.0,
        child: Backdrop(
          frontLayer: MyHomePage(),
          backLayer: Container(
            height: 100.0,
          ),
          fab: FloatingActionButton(
            onPressed: () {},
            tooltip: 'GO',
            child: Icon(Icons.smoking_rooms),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Location location = Location();
  String _currentCode = "";

  @override
  void initState() {
    super.initState();
    location.onLocationChanged().listen((update) {
      setState(() {
        _currentCode = encode(update["latitude"], update["longitude"], codeLength: 8);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(_currentCode),
    );
  }
}
