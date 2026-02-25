import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_location_wakeup/location_wakeup_platform.dart';

/// An implementation of [LocationWakeupPlatform] that uses method channels.
class MethodChannelLocationWakeup extends LocationWakeupPlatform {
  @visibleForTesting
  // ignore: public_member_api_docs
  final MethodChannel channel = const MethodChannel('loc');

  @visibleForTesting
  // ignore: public_member_api_docs
  final EventChannel locationEventChannel = const EventChannel('loc_stream');
  
  @visibleForTesting
  // ignore: public_member_api_docs
  final EventChannel visitEventChannel = const EventChannel('loc_visit_stream');

  Stream<dynamic>? _locationUpdates;
  Stream<dynamic>? _visitUpdates;

  @override
  Future<void> startMonitoring() => channel.invokeMethod('startMonitoring');

  @override
  Future<void> stopMonitoring() => channel.invokeMethod('stopMonitoring');

  @override
  Stream<dynamic> get locationUpdates {
    _locationUpdates ??= locationEventChannel.receiveBroadcastStream();
    return _locationUpdates!;
  }

  @override
  Future<void> startVisitMonitoring() =>
      channel.invokeMethod('startVisitMonitoring');

  @override
  Future<void> stopVisitMonitoring() =>
      channel.invokeMethod('stopVisitMonitoring');

  @override
  Stream<dynamic> get visitUpdates {
    _visitUpdates ??= visitEventChannel.receiveBroadcastStream();
    return _visitUpdates!;
  }
}
