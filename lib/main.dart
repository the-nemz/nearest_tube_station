import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'api/nearest.dart';
import 'widgets/station_card.dart';
import 'widgets/station_page.dart';

const railStoptypes = 'NaptanMetroStation,NaptanRailStation';
const busStoptypes = 'NaptanPublicBusCoachTram';

const railRadius = 2000;
const busRadius = 1000;

void main() {
  runApp(const MaterialApp(
    title: 'Tube Near Me',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? currentLocation;
  String stopTypes = railStoptypes;
  int searchRadius = railRadius;
  NearestStationResponse? nearestData;
  NearestStationResponse? nearestRailData;
  NearestStationResponse? nearestBusData;
  String nearestQuery = '';
  int tabIndex = 0;
  int numShown = 0;

  @override
  void initState() {
    super.initState();

    determinePosition().then((_) {
      getNearestStations().then((_) {
        const period = Duration(milliseconds: 250);
        Timer.periodic(period, (Timer t) {
          if (numShown < (nearestData?.stations.length ?? 0)) {
            setState(() {
              numShown = numShown + 1;
            });
          }
        });
      });

      Geolocator.getPositionStream().listen((Position? position) {
        if (position != null) {
          double distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              currentLocation?.latitude ?? 0,
              currentLocation?.longitude ?? 0);
          if (distance > 100) {
            setState(() {
              currentLocation = position;
            });

            getNearestStations();
          }
        }
      });
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    determinePosition();
  }

  Future<void> fetchNearestStations(String query) async {
    setState(() {
      numShown = 0;
    });

    print('Fetching nearest stations: $query');
    final response = await http.get(Uri.parse(query));

    if (response.statusCode == 200) {
      final data = NearestStationResponse.fromJson(jsonDecode(response.body));

      setState(() {
        if (tabIndex == 0) {
          nearestRailData = data;
        } else if (tabIndex == 1) {
          nearestBusData = data;
        }

        nearestData = data;
        nearestQuery = query;
        numShown = 1;
      });
    } else {
      print('${response.statusCode} - ${response.reasonPhrase}');
      throw Exception('Failed to load nearest stations');
    }
  }

  getNearestStations({bool forceReload = false}) async {
    if (currentLocation == null) {
      return;
    }

    String query =
        'https://api.tfl.gov.uk/StopPoint/?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&stopTypes=$stopTypes&radius=$searchRadius';

    if (nearestQuery != query || nearestData == null || forceReload) {
      if (forceReload) {
        setState(() {
          nearestData = null;
        });
      }

      await fetchNearestStations(query);
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    // return await Geolocator.getCurrentPosition();

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = pos;
    });
  }

  void _onItemTapped(int index) {
    if (index != tabIndex) {
      setState(() {
        nearestData = null;
      });

      if (index == 0) {
        setState(() {
          stopTypes = railStoptypes;
          searchRadius = railRadius;
          nearestData = nearestRailData;
          tabIndex = 0;
        });

        if (nearestRailData == null) {
          getNearestStations();
        }
      } else if (index == 1) {
        setState(() {
          stopTypes = busStoptypes;
          searchRadius = busRadius;
          nearestData = nearestBusData;
          tabIndex = 1;
        });

        if (nearestBusData == null) {
          getNearestStations();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: nearestData?.stations.isNotEmpty ?? false
              ? ListView.builder(
                  itemCount: nearestData?.stations.length ?? 0,
                  itemBuilder: (_, index) {
                    return AnimatedOpacity(
                      opacity: index < numShown ? 1.0 : 0.0,
                      curve: Curves.easeInOut,
                      duration: const Duration(milliseconds: 500),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StationPage(
                                  nearestData!.stations[index],
                                  currentLocation),
                            ),
                          );
                        },
                        child: StationCard(nearestData!.stations[index], index,
                            currentLocation),
                      ),
                    );
                  })
              : nearestData != null
                  ? const Text('There are no stations nearby.')
                  : const CircularProgressIndicator(),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          onPressed: () {
            determinePosition().then((_) {
              getNearestStations(forceReload: true);
            });
          },
          child: const Icon(Icons.refresh),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: tabIndex,
          selectedItemColor: Colors.deepOrange,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.train_outlined),
              label: 'Rail',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_filled_outlined),
              label: 'Bus',
            ),
          ],
        ),
      ),
    );
  }
}
