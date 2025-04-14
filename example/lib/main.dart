import 'dart:async';

import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/live_activity_file.dart';
import 'package:live_activities/models/url_scheme_data.dart';
import 'package:flutter_radar/flutter_radar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _liveActivitiesPlugin = LiveActivities();
  String? _latestActivityId;
  String currentGeofence = 'none';

  @override
  void initState() {
    super.initState();
    initRadar();

    _liveActivitiesPlugin.init(
        appGroupId: 'group.radar.liveactivities');

    _liveActivitiesPlugin.activityUpdateStream.listen((event) {
      print('Activity update: $event');
    });
  }

  @pragma('vm:entry-point')
  void onLocation(Map res) {
    print('📍📍 onLocation: $res');
    setState(() {
      currentGeofence = (res['user']['geofences'] as List).isNotEmpty 
          ? (res['user']['geofences'] as List).first['description'] 
          : 'none';
    });
    
    if (_latestActivityId != null) {
      _liveActivitiesPlugin.updateActivity(
        _latestActivityId!,
        {
          'memberName': 'Jennifer Rowling',
          'memberType': 'PRIMARY',
          'memberNumber': '801278123645', 
          'membershipLevel': 'Gold',
          'geofenceDescription': currentGeofence,
        },
      );
    }
  }

  @pragma('vm:entry-point')
  void onClientLocation(Map res) {
    print('📍📍 onClientLocation: $res');
  }

  @pragma('vm:entry-point')
  static void onError(Map res) {
    print('📍📍 onError: $res');
  }

  @pragma('vm:entry-point')
  static void onLog(Map res) {
    print('📍📍 onLog: $res');
  }

  @pragma('vm:entry-point')
  void onEvents(Map res) async {
    print('📍📍 onEvents: $res');
    if (res.containsKey('events')) {
      List events = res['events'];
      for (var event in events) {
        // start the live activity when we enter the geofence 
        if (event['type'] == 'user.entered_geofence' && event['geofence']['tag'] == 'store') {
          if (_latestActivityId == null) {
            // Start a live activity when user enters geofence
            final activityId = await _liveActivitiesPlugin.createActivity({
              'activityId': 'geofence_entry_${event['_id']}',
              'memberName': 'Jennifer Rowling',
              'memberType': 'PRIMARY',
              'memberNumber': '801278123645', 
              'membershipLevel': 'Gold',
              'geofenceDescription': event['geofence']['description'] ?? 'Unknown store',
            });
            setState(() => _latestActivityId = activityId);
          } else {
            _liveActivitiesPlugin.updateActivity(
              _latestActivityId!,
              {
                'activityId': 'geofence_entry_${event['_id']}',
                'memberName': 'Jennifer Rowling',
                'memberType': 'PRIMARY',
                'memberNumber': '801278123645', 
                'membershipLevel': 'Gold',
                'geofenceDescription': event['geofence']['description'] ?? 'Unknown store',
              } 
            );
          }
        }
        if (event['type'] == 'user.exited_geofence' && event['geofence']['tag'] == 'store') {
          _liveActivitiesPlugin.endAllActivities();
          setState(() => _latestActivityId = null); 
        }
      }
    }
  }

  @pragma('vm:entry-point')
  static void onToken(Map res) {
    print('📍📍 onToken: $res');
  }

  Future<void> initRadar() async {
    Radar.initialize('prj_test_pk_b3771406246d67aab4de4c58e90082ee476aee3d');
    Radar.setUserId('flutter');
    Radar.setDescription('Flutter');
    Radar.setMetadata({'foo': 'bar', 'LA': true, 'qux': 1});
    Radar.setLogLevel('info');
    Radar.setAnonymousTrackingEnabled(false);

    Radar.onLocation(onLocation);
    Radar.onClientLocation(onClientLocation);
    Radar.onError(onError);
    Radar.onEvents(onEvents);
    Radar.onLog(onLog);
    Radar.onToken(onToken);

    await Radar.requestPermissions(false);
    await Radar.requestPermissions(true);
    
    var permissionStatus = await Radar.getPermissionsStatus();
    if (permissionStatus != "DENIED") {
      var b = await Radar.startTrackingCustom({
        ... Radar.presetResponsive,
        "showBlueBar": true,
      });

      var c = await Radar.getTrackingOptions();
      print("Tracking options $c");
    }
    
    final enabled = await _liveActivitiesPlugin.areActivitiesEnabled();
    print("activities available: $enabled");
  }

  @override
  void dispose() {
    _liveActivitiesPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Activities (Flutter)',
          style: TextStyle(
            fontSize: 19,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_latestActivityId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Card(
                    child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                        children: [
                          const Text(
                            'Active Membership Card',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Current Location: $currentGeofence'),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_latestActivityId == null)
                TextButton(
                  onPressed: () async {
                    // Simple membership data
                    final membershipData = {
                      'activityId': 'membership_card_${DateTime.now().millisecondsSinceEpoch}',
                      'memberName': 'Jennifer Rowling',
                      'memberType': 'PRIMARY',
                      'memberNumber': '801278123645', 
                      'membershipLevel': 'Gold',
                      'geofenceDescription': currentGeofence,
                    };

                    final activityId = await _liveActivitiesPlugin.createActivity(membershipData);
                    setState(() => _latestActivityId = activityId);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Digital Membership Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_latestActivityId == null)
                TextButton(
                  onPressed: () async {
                    final supported = await _liveActivitiesPlugin.areActivitiesEnabled();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Text(
                              supported ? 'Supported' : 'Not supported',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Is live activities supported ? 🤔'),
                ),
              if (_latestActivityId != null)
                TextButton(
                  onPressed: () {
                    _liveActivitiesPlugin.endAllActivities();
                    _latestActivityId = null;
                    setState(() {});
                  },
                  child: const Column(
                    children: [
                      Text('Hide membership card'),
                      Text(
                        '(end all live activities)',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future _updateMembershipInfo() async {
    if (_latestActivityId == null) {
      return;
    }
    
    return _liveActivitiesPlugin.updateActivity(
      _latestActivityId!,
      {
        'memberName': 'Jennifer Rowling',
        'memberType': 'PRIMARY',
        'memberNumber': '801278123645', 
        'membershipLevel': 'Gold',
        'geofenceDescription': currentGeofence,
      },
    );
  }
}