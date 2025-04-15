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
  
  // New variables for enhanced functionality
  bool _loggingEnabled = true;
  String userId = 'flutter'; // Default from initialization
  int syncedGeofencesCount = 0;
  List<String> syncedGeofences = []; // Store just geofence IDs
  bool showGeofenceList = false;

  @override
  void initState() {
    super.initState();
    initRadar();

    _liveActivitiesPlugin.init(
        appGroupId: 'group.radar.liveactivities');

    _liveActivitiesPlugin.activityUpdateStream.listen((event) {
      _conditionalLog('Activity update: $event');
    });
  }

  // Conditional logging function
  void _conditionalLog(String message) {
    if (_loggingEnabled) {
      print(message);
    }
  }

  // Toggle logging
  void _toggleLogging() {
    setState(() {
      _loggingEnabled = !_loggingEnabled;
    });
  }

  // Toggle geofence list visibility
  void _toggleGeofenceList() {
    setState(() {
      showGeofenceList = !showGeofenceList;
    });
  }

  @pragma('vm:entry-point')
  void onLocation(Map res) {
    _conditionalLog('📍📍 onLocation: $res');
    setState(() {
      // Update the current geofence if available
      if (res.containsKey('user') && 
          res['user'] != null && 
          res['user'] is Map && 
          res['user'].containsKey('geofences')) {
        List geofences = res['user']['geofences'] as List;
        currentGeofence = geofences.isNotEmpty 
            ? geofences.first['description'] 
            : 'none';
      }
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
    _conditionalLog('📍📍 onClientLocation: $res');
  }

  @pragma('vm:entry-point')
  static void onError(Map res) {
    print('📍📍 onError: $res');
  }

  @pragma('vm:entry-point')
  void onLog(Map res) {
    _conditionalLog('📍📍 onLog: $res');
    
    // Parse log messages to detect synced geofences
    if (res.containsKey('message') && res['message'] is String) {
      String message = res['message'] as String;
      
      // Look for synced geofence messages
      if (message.contains('Synced geofence') && message.contains('radar_geofence_')) {
        _extractSyncedGeofenceInfo(message);
      }
      
      // Check for removed synced geofences
      if (message.contains('Removed synced geofences')) {
        setState(() {
          syncedGeofences.clear();
          syncedGeofencesCount = 0;
        });
      }
    }
  }
  
  void _extractSyncedGeofenceInfo(String message) {
    // Extract the radar_geofence_ identifier
    RegExp regExp = RegExp(r'identifier = (radar_geofence_[^;|\s]+)');
    Match? match = regExp.firstMatch(message);
    
    if (match != null && match.groupCount >= 1) {
      String geofenceId = match.group(1)!;
      
      // Check if we already have this geofence
      if (!syncedGeofences.contains(geofenceId)) {
        setState(() {
          syncedGeofences.add(geofenceId);
          syncedGeofencesCount = syncedGeofences.length;
        });
      }
    }
  }

  @pragma('vm:entry-point')
  void onEvents(Map res) async {
    _conditionalLog('📍📍 onEvents: $res');
    if (res.containsKey('events')) {
      List events = res['events'];
      for (var event in events) {
        // Extract geofence IDs from events
        if (event['type'] == 'user.entered_geofence' || 
            event['type'] == 'user.exited_geofence') {
          if (event.containsKey('geofence') && event['geofence'] is Map) {
            var geofence = event['geofence'] as Map;
            if (geofence.containsKey('_id')) {
              String geofenceId = geofence['_id'].toString();
              
              // Only process radar_geofence_ IDs
              if (geofenceId.startsWith('radar_geofence_') && 
                  !syncedGeofences.contains(geofenceId)) {
                setState(() {
                  syncedGeofences.add(geofenceId);
                  syncedGeofencesCount = syncedGeofences.length;
                });
              }
            }
          }
        }
        
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
    setState(() {
      userId = 'flutter'; // Store the userId for display
    });
    
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
      _conditionalLog("Tracking options $c");
    }
    
    final enabled = await _liveActivitiesPlugin.areActivitiesEnabled();
    _conditionalLog("activities available: $enabled");
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
        backgroundColor: const Color(0xFF000257),
        actions: [
          // Add a logging toggle button in the app bar
          IconButton(
            icon: Icon(
              _loggingEnabled ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: _toggleLogging,
            tooltip: _loggingEnabled ? 'Disable Logs' : 'Enable Logs',
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display User ID and Current Geofence
              Card(
                color: const Color(0xFFF5F5F5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('User ID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(userId, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Current Geofence: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(currentGeofence, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Geofence count and list button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _toggleGeofenceList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000257),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Synced Geofences (${syncedGeofencesCount})'),
                ),
              ),
              
              // Display geofence list if toggled - now with more space for scrolling
              if (showGeofenceList)
                Expanded(
                  child: Card(
                    color: const Color(0xFFF5F5F5),
                    child: syncedGeofences.isEmpty
                      ? const Center(child: Text('No geofences synced yet'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: syncedGeofences.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              child: Text(
                                syncedGeofences[index],
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          },
                        ),
                  ),
                ),
              
              if (!showGeofenceList)
                const Spacer(),
                
              if (_latestActivityId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Card(
                    color: const Color(0xFF000257),
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Location: $currentGeofence',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
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
                    backgroundColor: const Color(0xFF000257),
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