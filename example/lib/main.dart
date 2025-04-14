import 'dart:async';

import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/live_activity_file.dart';
import 'package:live_activities/models/url_scheme_data.dart';
import 'package:live_activities_example/models/football_game_live_activity_model.dart';
import 'package:live_activities_example/widgets/score_widget.dart';
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
  //StreamSubscription<UrlSchemeData>? urlSchemeSubscription;
  FootballGameLiveActivityModel? _footballGameLiveActivityModel;

  int teamAScore = 0;
  int teamBScore = 0;

  String teamAName = 'PSG';
  String teamBName = 'Chelsea';

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

    // urlSchemeSubscription =
    //     _liveActivitiesPlugin.urlSchemeStream().listen((schemeData) {
    //   setState(() {
    //     if (schemeData.path == '/stats') {
    //       showDialog(
    //         context: context,
    //         builder: (BuildContext context) {
    //           return AlertDialog(
    //             title: const Text('Stats 📊'),
    //             content: Text(
    //               'Now playing final world cup between $teamAName and $teamBName\n\n$teamAName score: $teamAScore\n$teamBName score: $teamBScore',
    //             ),
    //             actions: [
    //               TextButton(
    //                 onPressed: () => Navigator.of(context).pop(),
    //                 child: const Text('Close'),
    //               ),
    //             ],
    //           );
    //         },
    //       );
    //     }
    //   });
    // });
  }

  @pragma('vm:entry-point')
  void onLocation(Map res) {
    print('📍📍 onLocation: $res');
    setState(() {
      currentGeofence = (res['user']['geofences'] as List).isNotEmpty ? (res['user']['geofences'] as List).first['description'] : 'none';
      
    });
    _liveActivitiesPlugin.updateActivity(
        _latestActivityId!,
        { ..._footballGameLiveActivityModel!.toMap(), 'geofenceDescription': currentGeofence },
      );
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
                if (event['type'] == 'user.entered_geofence' && event['geofence']['tag'] == 'YOUR_TAG_FOR_LIVE_ACTIVITY') {
                    if (_latestActivityId == null) {
                         // Start a live activity when user enters geofence
                        final activityId = await _liveActivitiesPlugin.createActivity({
                            'activityId': 'geofence_entry_${event['_id']}',
                            'activityAttributes': {
                                'geofenceName': event['geofence']['description'] ?? 'Unknown geofence',
                                'enteredAt': DateTime.now().toIso8601String(),
                            }
                        });
                        setState(() => _latestActivityId = activityId);
                    } else {
                        _liveActivitiesPlugin.updateActivity(
                           _latestActivityId!,
                           {
                                'activityId': 'geofence_entry_${event['_id']}',
                                'activityAttributes': {
                                    'geofenceName': event['geofence']['description'] ?? 'Unknown geofence',
                                    'enteredAt': DateTime.now().toIso8601String(),
                                }
                           } 
                        );
                    }
                   
                }
                if (event['type'] == 'user.exited_geofence' && event['geofence']['tag'] == 'YOUR_TAG_FOR_LIVE_ACTIVITY') {
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
    Radar.initialize('prj_test_pk_4899327d5733b7741a3bfa223157f3859273be46');
    Radar.setUserId('flutter');
    Radar.setDescription('Flutter');
    Radar.setMetadata({'foo': 'bar', 'bax': true, 'qux': 1});
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

  final Map<String, dynamic> activityModel = {
    'name': 'Margherita',
    'ingredient': 'tomato, mozzarella, basil',
    'quantity': 1,
  };

  @override
  void dispose() {
    //urlSchemeSubscription?.cancel();
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(
                            child: ScoreWidget(
                              score: teamAScore,
                              teamName: teamAName,
                              onScoreChanged: (score) {
                                setState(() {
                                  teamAScore = score < 0 ? 0 : score;
                                });
                                _updateScore();
                              },
                            ),
                          ),
                          Expanded(
                            child: ScoreWidget(
                              score: teamBScore,
                              teamName: teamBName,
                              onScoreChanged: (score) {
                                setState(() {
                                  teamBScore = score < 0 ? 0 : score;
                                });
                                _updateScore();
                              },
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
                    _footballGameLiveActivityModel =
                        FootballGameLiveActivityModel(
                      matchName: 'World cup ⚽️',
                      teamAName: 'PSG',
                      teamAState: 'Home',
                      ruleFile:
                          LiveActivityFileFromAsset('assets/files/rules.txt'),
                      teamALogo: LiveActivityFileFromAsset.image(
                        'assets/images/psg.png',
                      ),
                      teamBLogo: LiveActivityFileFromAsset.image(
                          'assets/images/chelsea.png',
                          imageOptions:
                              LiveActivityImageFileOptions(resizeFactor: 0.2)),
                      teamBName: 'Chelsea',
                      teamBState: 'Guest',
                      matchStartDate: DateTime.now(),
                      matchEndDate: DateTime.now().add(
                        const Duration(
                          minutes: 6,
                          seconds: 30,
                        ),
                      ),
                    );

                    final activityId =
                        await _liveActivitiesPlugin.createActivity(
                      {
                        ..._footballGameLiveActivityModel!.toMap(),
                        'geofenceDescription': currentGeofence,
                      },
                    );
                    setState(() => _latestActivityId = activityId);
                  },
                  child: const Column(
                    children: [
                      Text('Start football match ⚽️'),
                      Text(
                        '(start a new live activity)',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_latestActivityId == null)
                TextButton(
                  onPressed: () async {
                    final supported =
                        await _liveActivitiesPlugin.areActivitiesEnabled();
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
                      Text('Stop match ✋'),
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

  Future _updateScore() async {
    if (_footballGameLiveActivityModel == null) {
      return;
    }

    final data = _footballGameLiveActivityModel!.copyWith(
      teamAScore: teamAScore,
      teamBScore: teamBScore,
      // teamAName: null,
    );
    return _liveActivitiesPlugin.updateActivity(
      _latestActivityId!,
      { ...data.toMap(), 'geofenceDescription': currentGeofence },
    );
  }
}
