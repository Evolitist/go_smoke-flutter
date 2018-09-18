import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

class Permissions {
  final PermissionHandler _handler;

  Permissions() : _handler = PermissionHandler();

  Future<bool> requestLocationPermissions(
      [bool countRestricted = false]) async {
    PermissionStatus status =
        await _handler.checkPermissionStatus(PermissionGroup.location);
    bool restricted =
        countRestricted ? status == PermissionStatus.restricted : false;
    if (status == PermissionStatus.granted || restricted) {
      return true;
    } else {
      Map<PermissionGroup, PermissionStatus> result =
          await _handler.requestPermissions([PermissionGroup.location]);
      restricted = countRestricted
          ? result[PermissionGroup.location] == PermissionStatus.restricted
          : false;
      return result[PermissionGroup.location] == PermissionStatus.granted ||
          restricted;
    }
  }
}
