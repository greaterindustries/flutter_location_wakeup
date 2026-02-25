import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_location_wakeup/flutter_location_wakeup.dart';

///Monitors the device's location for significant changes and wakes up the app
///when there is a change
class LocationWakeup {
  ///Constructs a LocationWakeup plugin
  LocationWakeup() {
    _locationSubscription = LocationWakeupPlatform.instance.locationUpdates
      .listen(
        (event) {
          _locationController.add(toLocationResult(event));
        },
        // ignore: avoid_annotating_with_dynamic
        onError: (dynamic error) => streamError(_locationController, error),
      );

    _finalizer.attach(
      this, 
      _CleanupToken(_locationController, _visitController, _stopAll),
      detach: this,
    );
  }

  static final _finalizer = Finalizer<_CleanupToken>((token) async {
    debugPrint('LocationWakeup being finalized - cleaning up resources');
    await Future.wait([
      token.locationController.close(),
      token.visitController.close(),
      token.stopCallback(),
    ]);
  });

  final _locationController = StreamController<LocationResult>.broadcast();
  final _visitController = StreamController<VisitResult>.broadcast();
  StreamSubscription<dynamic>? _locationSubscription;
  StreamSubscription<dynamic>? _visitSubscription;
  bool _isMonitoringLocation = false;
  bool _isMonitoringVisits = false;
  bool _isDisposed = false;

  ///Start listening for location changes
  Future<void> startMonitoring() async {
    if (_isDisposed) {
      throw StateError('LocationWakeup has been disposed');
    }
    if (_isMonitoringLocation) return;
    
    _locationSubscription = LocationWakeupPlatform.instance.locationUpdates
    .listen(
      (event) {
        if (!_locationController.isClosed) {
          _locationController.add(toLocationResult(event));
        }
      },
      // ignore: avoid_annotating_with_dynamic
      onError: (dynamic error) => streamError(_locationController, error),
    );
    
    await LocationWakeupPlatform.instance.startMonitoring();
    _isMonitoringLocation = true;
  }

  ///Start listening for visit changes
  Future<void> startVisitMonitoring() async {
    if (_isDisposed) {
      throw StateError('LocationWakeup has been disposed');
    }
    if (_isMonitoringVisits) return;
    
    _visitSubscription = LocationWakeupPlatform.instance.visitUpdates.listen(
      (event) {
        if (!_visitController.isClosed) {
          _visitController.add(toVisitResult(event));
        }
      },
    );
    
    await LocationWakeupPlatform.instance.startVisitMonitoring();
    _isMonitoringVisits = true;
  }

  ///Stops listening to the system location changes and disposes platform
  ///resources. This plugin is only designed to start once, so if you need
  ///to listen again, you will need to create a new instance of this plugin.
  Future<void> stopMonitoring() async {
    if (_isDisposed) return;
    if (!_isMonitoringLocation) return;
    await _stopLocationMonitoring();
  }

  ///Stops listening to the system visit changes and disposes platform resources
  Future<void> stopVisitMonitoring() async {
    if (_isDisposed) return;
    if (!_isMonitoringVisits) return;
    await _stopVisitMonitoring();
  }

  Future<void> _stopLocationMonitoring() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await LocationWakeupPlatform.instance.stopMonitoring();
    _isMonitoringLocation = false;
  }

  Future<void> _stopVisitMonitoring() async {
    await _visitSubscription?.cancel();
    _visitSubscription = null;
    await LocationWakeupPlatform.instance.stopVisitMonitoring();
    _isMonitoringVisits = false;
  }

  Future<void> _stopAll() async {
    await Future.wait([
      _stopLocationMonitoring(),
      _stopVisitMonitoring(),
    ]);
  }

  /// LocationWakeup will automatically clean up its resources when the instance
  /// is garbage collected, but it's recommended to call dispose() explicitly
  ///  when you're done with it to ensure timely resource cleanup.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await Future.wait([
      _stopAll(),
      _locationController.close(),
      _visitController.close(),
    ]);
    _finalizer.detach(this);
  }

  ///A stream of location changes
  Stream<LocationResult> get locationUpdates => _locationController.stream;

  ///A stream of visit changes
  Stream<VisitResult> get visitUpdates => _visitController.stream;
}

class _CleanupToken {
  const _CleanupToken(
    this.locationController,
    this.visitController,
    this.stopCallback,
  );
  
  final StreamController<LocationResult> locationController;
  final StreamController<VisitResult> visitController;
  final Future<void> Function() stopCallback;
}

@visibleForTesting
// ignore: public_member_api_docs
void streamError(
  // ignore: strict_raw_type
  StreamController<Result> controller,
  // ignore: avoid_annotating_with_dynamic
  dynamic error,
) {
  if (error is PlatformException) {
    String? permissionStatusString;
    if (error.details is Map) {
      final details = error.details as Map;
      permissionStatusString = details['permissionStatus'] as String?;
    }
    
    final errorCode = error.code.toErrorCode();
    controller.add(
      // ignore: inference_failure_on_instance_creation
      Result.error(
        Error(
          message: error.message ?? _getDefaultErrorMessage(errorCode),
          errorCode: errorCode,
        ),
        permissionStatus: permissionStatusString.toPermissionStatus(),
      ),
    );
    return;
  }

  // ignore: inference_failure_on_function_invocation
  controller.add(Result.unknownError());
}

String _getDefaultErrorMessage(ErrorCode code) => switch (code) {
      ErrorCode.locationPermissionDenied => 'Location permission denied',
      ErrorCode.significantLocationMonitoringUnavailable =>
          'Significant location monitoring unavailable',
      ErrorCode.unknown => 'Unknown (likely OS-level) error occurred',
      ErrorCode.none => 'No error',
    };
