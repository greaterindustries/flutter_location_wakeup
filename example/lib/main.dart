import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_location_wakeup/flutter_location_wakeup.dart';
import 'nully_extensions.dart';

final messengerStateKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    scaffoldMessengerKey: messengerStateKey,
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Location & Visit Monitoring'),
      ),
      body: const Center(
        child: MonitoringDisplay(),
      ),
    ),
  ));
}

class MonitoringDisplay extends StatefulWidget {
  const MonitoringDisplay({Key? key}) : super(key: key);

  @override
  State<MonitoringDisplay> createState() => _MonitoringDisplayState();
}

class _MonitoringDisplayState extends State<MonitoringDisplay> {
  String _locationDisplay = 'No location updates';
  String _visitDisplay = 'No visit updates';
  final _locationWakeup = LocationWakeup();
  bool _isMonitoringLocation = false;
  bool _isMonitoringVisits = false;

  @override
  void dispose() {
    _locationWakeup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonitoringSection(
              title: 'Location Monitoring',
              isMonitoring: _isMonitoringLocation,
              display: _locationDisplay,
              onStartStop: _toggleLocationMonitoring,
            ),
            const SizedBox(height: 24),
            _buildMonitoringSection(
              title: 'Visit Monitoring',
              isMonitoring: _isMonitoringVisits,
              display: _visitDisplay,
              onStartStop: _toggleVisitMonitoring,
            ),
          ],
        ),
      );

  Widget _buildMonitoringSection({
    required String title,
    required bool isMonitoring,
    required String display,
    required Future<void> Function() onStartStop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            ElevatedButton(
              onPressed: onStartStop,
              child: Text(isMonitoring ? 'Stop' : 'Start'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(display),
        ),
      ],
    );
  }

  Future<void> _toggleLocationMonitoring() async {
    if (!mounted) return;

    try {
      if (_isMonitoringLocation) {
        await _locationWakeup.stopMonitoring();
        setState(() {
          _isMonitoringLocation = false;
          _locationDisplay = 'Monitoring stopped';
        });
      } else {
        _locationWakeup.locationUpdates.listen(
          (result) {
            if (!mounted) return;
            setState(() => _locationDisplay = _formatLocationResult(result));
          },
        );
        await _locationWakeup.startMonitoring();
        setState(() => _isMonitoringLocation = true);
      }
    } on PlatformException catch (e) {
      _showError('Location Monitoring Error', e.message ?? 'Unknown error occurred');
    }
  }

  Future<void> _toggleVisitMonitoring() async {
    if (!mounted) return;

    try {
      if (_isMonitoringVisits) {
        await _locationWakeup.stopVisitMonitoring();
        setState(() {
          _isMonitoringVisits = false;
          _visitDisplay = 'Monitoring stopped';
        });
      } else {
        _locationWakeup.visitUpdates.listen(
          (result) {
            if (!mounted) return;
            setState(() => _visitDisplay = _formatVisitResult(result));
          },
        );
        await _locationWakeup.startVisitMonitoring();
        setState(() => _isMonitoringVisits = true);
      }
    } on PlatformException catch (e) {
      _showError('Visit Monitoring Error', e.message ?? 'Unknown error occurred');
    }
  }

  String _formatLocationResult(LocationResult result) {
    return result.match(
      onSuccess: (location) => '''
Location Update:
Lat: ${location.latitude}
Long: ${location.longitude}
Altitude: ${location.altitude ?? 'N/A'}
Accuracy: ${location.horizontalAccuracy ?? 'N/A'}m
Speed: ${location.speed ?? 'N/A'}
Time: ${location.timestamp ?? 'N/A'}
''',
      onError: (e) => 'Error: ${e.message}\nStatus: ${result.permissionStatus}',
    );
  }

  String _formatVisitResult(VisitResult result) {
    return result.match(
      onSuccess: (visit) => '''
Visit Detected:
Location: ${visit.latitude}, ${visit.longitude}
Arrival: ${visit.arrivalTimestamp}
Departure: ${visit.departureTimestamp}
Accuracy: ${visit.horizontalAccuracy}m
''',
      onError: (e) => 'Error: ${e.message}\nStatus: ${result.permissionStatus}',
    );
  }

  void _showError(String title, String message) {
    messengerStateKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}


class LocationDisplay extends StatefulWidget {
  const LocationDisplay({Key? key}) : super(key: key);

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  String _display = 'Unknown';
  final _locationWakeup = LocationWakeup();

  @override
  void initState() {
    super.initState();
    startListening();
  }

  Future<void> startListening() async {
    if (!mounted) return;

    try {
      //Start listening before initializing
      _locationWakeup.locationUpdates.listen(
        (result) {
          if (!mounted) return;

          setState(() => onLocationResultChange(result));
        },
      );
      //Initialize
      await _locationWakeup.startMonitoring();
    } on PlatformException {
      // Handle exception
    }
  }

  void onLocationResultChange(LocationResult result) {
    _display = result.match(
        onSuccess: (l) => '''
Lat: ${l.latitude}
Long: ${l.longitude}
Altitude: ${l.altitude}
Horizontal Accuracy: ${l.horizontalAccuracy}
Vertical Accuracy: ${l.verticalAccuracy}
Course: ${l.course}
Speed: ${l.speed}
Timestamp: ${l.timestamp}
Floor Level: ${l.floorLevel}
''',
        onError: (e) => e.message);

    messengerStateKey.currentState.let(
      (state) async => state.showSnackBar(
        SnackBar(
          content: Text(
            _display,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(state.context).colorScheme.background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Text(_display);
}
