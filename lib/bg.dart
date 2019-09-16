import 'package:flutter/services.dart';

const MethodChannel bgChannel = MethodChannel('gsmk_bg');

void bgMain() {
  bgChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      default:
        throw MissingPluginException();
    }
  });
}
