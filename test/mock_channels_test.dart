import 'package:flutter/services.dart';
import 'package:flutter_location_wakeup/flutter_location_wakeup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Receives events from the event channel', (tester) async {
    var receivedStartMonitoring = false;

    final plugin = LocationWakeup();

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('loc'),
      (methodCall) async {
        if (methodCall.method == 'startMonitoring') {
          receivedStartMonitoring = true;
          return null;
        }
        throw PlatformException(
          code: 'UNAVAILABLE',
          message: 'Mock error message',
        );
      },
    );

    TestWidgetsFlutterBinding.ensureInitialized();

    await plugin.startMonitoring();

    final locationData = <String, dynamic>{
      'latitude': 40.7128,
      'longitude': -74.0060,
      'altitude': 500.0,
      'speed': 5.0,
      'timestamp': 1677648652.0,
      'permissionStatus': 'granted',
    };

    final methodCall = MethodCall('listen', locationData);

    final encodedData =
        const StandardMethodCodec().encodeMethodCall(methodCall);

    final methodChannelLocationWakeup =
        LocationWakeupPlatform.instance as MethodChannelLocationWakeup;

    final fakeStreamHandler = FakeStreamHandler();
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      methodChannelLocationWakeup.eventChannel,
      fakeStreamHandler,
    );

    await methodChannelLocationWakeup.eventChannel.binaryMessenger
        .send('loc_stream', encodedData);

    final events = await plugin.locationUpdates.first;

    expect(
      events,
      isNotEmpty,
    );

    expect(receivedStartMonitoring, isTrue);
  });
}

class FakeStreamHandler extends MockStreamHandler {
  @override
  void onCancel(Object? arguments) {
    // TODO: implement onCancel
  }

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    events.success(arguments);
    // TODO: implement onListen
  }
}
