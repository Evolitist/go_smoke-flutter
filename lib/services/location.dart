import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import 'permissions.dart';

class Location {
  final Geolocator _location;
  final Permissions _permissions;

  Location() : _location = Geolocator(), _permissions = Permissions();

  Future<Option<Stream<Position>>> getLocationStream() async {
    if (await _permissions.requestLocationPermissions()) {
      return some(await _location.getPositionStream());
    } else {
      return none();
    }
  }
}