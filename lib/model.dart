///The result of a location change from the device
class LocationResult {
  ///Successful result
  const LocationResult(
    Location location, {
    required this.permissionStatus,
  })  : _location = location,
        _error = null;

  ///Error from the device
  const LocationResult.error(
    Error error, {
    required this.permissionStatus,
  })  : _error = error,
        _location = null;

  final Location? _location;
  final Error? _error;

  ///True if the result is a success
  bool get isSuccess => _location != null;

  ///True if the result is an error
  bool get isError => _error != null;

  ///The permission status of the location permission if the device
  ///sent it
  final PermissionStatus permissionStatus;

  static const unknownError = LocationResult.error(
    Error.unknown,
    permissionStatus: PermissionStatus.notSpecified,
  );

  ///Allows you to access the location if it is successful or
  ///the error if it is not
  T match<T>({
    required T Function(Location location) onSuccess,
    required T Function(Error error) onError,
  }) =>
      isSuccess ? onSuccess(_location!) : onError(_error!);

  ///Allows you to access the location if it is successful or
  ///to replace the location with a different value based on an error
  Location locationOr(Location Function(Error error) onError) =>
      isSuccess ? _location! : onError(_error!);

  /// Returns the location if it's successful, or an empty location if it's an
  /// error.
  Location get locationOrEmpty => _location ?? Location.empty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationResult &&
        other._location == _location &&
        other.permissionStatus == permissionStatus &&
        other._error == _error;
  }

  @override
  int get hashCode => _location.hashCode ^ _error.hashCode;

  @override
  String toString() => 'LocationResult(_location: $_location, _error: $_error)';
}

///Represents the type of error that occurred at the device level
enum ErrorCode {
  ///The app doesn't have permission to access location
  locationPermissionDenied,

  ///No known information from the device about what went wrong
  unknown,
}

///Represents the status of the location permission on the device
enum PermissionStatus {
  // Common statuses

  ///Permission is granted
  granted,

  /// Permission is denied but can be requested again.
  denied,

  /// Permission is denied and cannot be requested again without user
  /// intervention.
  permanentlyDenied,

  // iOS specific statuses

  /// User has not yet made a choice with regards to this
  /// application.
  notDetermined,

  /// This application is not authorized to use location services
  /// due to active restrictions.
  restricted,

  // Android specific statuses

  /// On Android Q and above, represents that only foreground location
  /// permission is granted, and background access is denied.
  limited,

  ///We have no information from the device about the permission status
  notSpecified,
}

///Represents an error from the device in regards to location
class Error {
  ///Creates an error with the given message and error code
  const Error({required this.message, required this.errorCode});

  ///The textual message of the error
  final String message;

  ///The error code representing the type of error
  final ErrorCode errorCode;

  ///Represents an unknown error with no information from the device
  static const unknown = Error(
    message: 'Unknown',
    errorCode: ErrorCode.unknown,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Error &&
        other.message == message &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode => message.hashCode ^ errorCode.hashCode;

  @override
  String toString() => 'Error(message: $message, errorCode: $errorCode)';
}

///Represents a location on earth by latitude and longitude and other optional
///information
class Location {
  ///Creates a location
  const Location({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.horizontalAccuracy,
    this.verticalAccuracy,
    this.course,
    this.speed,
    this.timestamp,
    this.floorLevel,
  });

  final double? altitude;
  final double? horizontalAccuracy;
  final double? verticalAccuracy;
  final double? course;
  final double? speed;
  final DateTime? timestamp;
  final int? floorLevel;

  ///The latitude of the location
  final double latitude;

  ///The longitude of the location
  final double longitude;

  ///Represents an empty or undefined location
  static const empty = Location(latitude: double.nan, longitude: double.nan);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'Location(latitude: $latitude, longitude: $longitude)';
}
