import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'permissions.dart';

class Location {
  static final Location _singleton = Location._();
  final Geolocator _location = Geolocator();
  final Permissions _permissions = Permissions();

  factory Location() => _singleton;

  Location._();

  Future<Stream<Position>> getLocationStream() async {
    if (await _permissions.requestLocationPermissions()) {
      return _location.getPositionStream();
    } else {
      return Stream.empty();
    }
  }

  Future<Position> getLastKnownPosition() async {
    return await _location.getLastKnownPosition();
  }
}
