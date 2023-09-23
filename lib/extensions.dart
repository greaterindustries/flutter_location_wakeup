import 'package:flutter_location_wakeup/flutter_location_wakeup.dart';

///Extensions for the [PermissionStatus] enum
extension PermissionsOnStringExtension on String? {
  ///Converts the device level permission status to the plugin level permission
  PermissionStatus toPermissionStatus() => switch (this) {
        null => PermissionStatus.notSpecified,
        'granted' => PermissionStatus.granted,
        'denied' => PermissionStatus.denied,
        'permanentlyDenied' => PermissionStatus.permanentlyDenied,
        'notDetermined' => PermissionStatus.notDetermined,
        'restricted' => PermissionStatus.restricted,
        'limited' => PermissionStatus.limited,
        _ => PermissionStatus.notSpecified,
      };
}

/// Extensions for nullable types
extension NullyExtensions<T> on T? {
  ///Allows you to perform an async action on a value only when that value is
  ///not null. and happens first because its synchronous
  Future<void> let(
    Future<void> Function(T) action, {
    void Function(T)? and,
  }) async {
    if (this != null) and?.call(this as T);
    return this != null ? action(this as T) : Future<void>.value();
  }

  ///Whether or not this variable has a non-null value
  bool get hasValue => this != null;
}

///Converts the platform data, possibly including the lat/log [LocationResult]
///to the result object
// ignore: avoid_annotating_with_dynamic
LocationResult toLocationResult(dynamic platformData) {
  if (platformData is Map) {
    final latitude = platformData['latitude'];
    final longitude = platformData['longitude'];
    final permissionStatusString = platformData['permissionStatus'] as String?;

    if (latitude is! double ||
        longitude is! double) {
      return LocationResult.error(
        const Error(
          message: 'Latitude or longitude is missing',
          errorCode: ErrorCode.unknown,
        ),
        permissionStatus: permissionStatusString.toPermissionStatus(),
      );
    }

    final altitude = platformData['altitude'] as double?;
    final horizontalAccuracy = platformData['horizontalAccuracy'] as double?;
    final verticalAccuracy = platformData['verticalAccuracy'] as double?;
    final course = platformData['course'] as double?;
    final speed = platformData['speed'] as double?;
    final unixTimestamp = platformData['timestamp'] as double?;

    final timestamp = unixTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(unixTimestamp.toInt() * 1000)
        : null;

    final floorLevel = platformData['floorLevel'] as int?;

    return LocationResult(
      Location(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        horizontalAccuracy: horizontalAccuracy,
        verticalAccuracy: verticalAccuracy,
        course: course,
        speed: speed,
        timestamp: timestamp,
        floorLevel: floorLevel,
      ),
      permissionStatus: permissionStatusString.toPermissionStatus(),
    );
  }

  // If this happens, please record the value in platformData and open an issue
  // on the github repo
  return LocationResult.unknownError;
}
