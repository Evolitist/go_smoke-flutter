import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import 'permissions.dart';

class Location {
  static final Location _singleton = Location._();
  final Geolocator _location = Geolocator();
  final Permissions _permissions = Permissions();

  factory Location() => _singleton;

  Location._();

  Future<Option<Stream<Position>>> getLocationStream() async {
    if (await _permissions.requestLocationPermissions()) {
      return some(await _location.getPositionStream());
    } else {
      return none();
    }
  }

  Future<Position> getLastKnownPosition() async {
    return await _location.getLastKnownPosition();
  }
}
