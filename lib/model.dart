/// A generic result type that can represent either a success or error state
final class Result<T> {
  /// Successful result
  const Result(
    T value, {
    required this.permissionStatus,
  })  : _value = value,
        _error = null;

  /// Error result
  const Result.error(
    Error error, {
    required this.permissionStatus,
  })  : _error = error,
        _value = null;

  final T? _value;
  final Error? _error;

  /// True if the result represents a success
  bool get isSuccess => _value != null;

  /// True if the result represents an error
  bool get isError => _error != null;

  /// The permission status from the device
  final PermissionStatus permissionStatus;

  /// Creates an unknown error result
  static Result<T> unknownError<T>() => Result<T>.error(
        Error.unknown,
        permissionStatus: PermissionStatus.notSpecified,
      );

  /// Pattern match on the result
  R match<R>({
    required R Function(T value) onSuccess,
    required R Function(Error error) onError,
  }) =>
      isSuccess ? onSuccess(_value as T) : onError(_error!);

  /// Get the value or map the error to a value
  T valueOr(T Function(Error error) onError) =>
      isSuccess ? _value! : onError(_error!);

  /// Get the error or an empty error
  Error errorOrEmpty() => isError ? _error! : Error.empty;

  /// Get the value or a default empty value
  T valueOrEmpty(T empty) => _value ?? empty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Result<T> &&
        other._value == _value &&
        other._error == _error &&
        other.permissionStatus == permissionStatus;
  }

  @override
  int get hashCode =>
      _value.hashCode ^ _error.hashCode ^ permissionStatus.hashCode;

  @override
  String toString() =>
      'Result(_value: $_value, _error: $_error, '
      'permissionStatus: $permissionStatus)';
}

/// A result type for location data
typedef LocationResult = Result<Location>;
/// A result type for visit data
typedef VisitResult = Result<Visit>;

///Represents the type of error that occurred at the device level
enum ErrorCode {
  ///The app doesn't have permission to access location
  locationPermissionDenied,

  ///The device does not have the ability to use significant location monitoring
  significantLocationMonitoringUnavailable,

  ///No known information from the device about what went wrong
  unknown,

  ///Not an error
  none,
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
final class Error {
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

  ///No error
  static const empty = Error(
    message: '',
    errorCode: ErrorCode.none,
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
final class Location {
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

  /// The altitude of the location in meters above the WGS 84 reference
  /// ellipsoid.
  /// Null if the altitude is not available.
  final double? altitude;

  /// The accuracy of the horizontal coordinate in meters. Represents the radius
  /// of uncertainty for the location's latitude and longitude.
  /// Null if the horizontal accuracy is not available.
  final double? horizontalAccuracy;

  /// The accuracy of the vertical coordinate (altitude) in meters. Represents
  /// the
  /// vertical accuracy of the altitude property.
  /// Null if the vertical accuracy is not available.
  final double? verticalAccuracy;

  /// The direction in which the device is traveling, measured in degrees and
  /// relative to due north. Value ranges from `0.0` to `359.99`.
  /// Null if the course is not available.
  final double? course;

  /// The instantaneous speed of the device in meters per second.
  /// Null if the speed is not available.
  final double? speed;

  /// The timestamp at which this location data was generated.
  /// Null if the timestamp is not available.
  final DateTime? timestamp;

  /// The floor level in buildings, relative to the building model.
  /// For example, if you are on the first floor, the value would be `1`.
  /// Null if the floor level is not available or if the device is not in a
  /// building.
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
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.horizontalAccuracy == horizontalAccuracy &&
        other.verticalAccuracy == verticalAccuracy &&
        other.course == course &&
        other.speed == speed &&
        other.timestamp == timestamp &&
        other.floorLevel == floorLevel;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      (altitude?.hashCode ?? 0) ^
      (horizontalAccuracy?.hashCode ?? 0) ^
      (verticalAccuracy?.hashCode ?? 0) ^
      (course?.hashCode ?? 0) ^
      (speed?.hashCode ?? 0) ^
      (timestamp?.hashCode ?? 0) ^
      (floorLevel?.hashCode ?? 0);

  @override
  String toString() => 'Location(latitude: $latitude, longitude: $longitude)';
}

/// Represents a visit to a location as detected by the device
final class Visit {

  /// Creates a visit
  const Visit({
    required this.arrivalTimestamp,
    required this.departureTimestamp,
    required this.latitude,
    required this.longitude,
    required this.horizontalAccuracy,
  });

  /// The date and time at which the device arrived at the location
  final DateTime arrivalTimestamp;
  /// The date and time at which the device departed from the location
  final DateTime departureTimestamp;
  /// The latitude of the location
  final double latitude;
  /// The longitude of the location
  final double longitude;
  /// The accuracy of the horizontal coordinate in meters. 
  final double horizontalAccuracy;

  /// Represents an empty or undefined visit
  static final empty = Visit(
    arrivalTimestamp: DateTime.fromMillisecondsSinceEpoch(0),
    departureTimestamp: DateTime.fromMillisecondsSinceEpoch(0),
    latitude: double.nan,
    longitude: double.nan,
    horizontalAccuracy: double.nan,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Visit &&
        other.arrivalTimestamp == arrivalTimestamp &&
        other.departureTimestamp == departureTimestamp &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.horizontalAccuracy == horizontalAccuracy;
  }

  @override
  int get hashCode => arrivalTimestamp.hashCode ^
        departureTimestamp.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        horizontalAccuracy.hashCode;

  @override
  String toString() =>
      'Visit(arrivalDate: $arrivalTimestamp, '
      'departureDate: $departureTimestamp, '
      'latitude: $latitude, longitude: $longitude)';
}
