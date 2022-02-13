import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'api/nearest.dart';
import 'widgets/station_card.dart';

const railStoptypes = 'NaptanMetroStation,NaptanRailStation';
const busStoptypes = 'NaptanPublicBusCoachTram';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? currentLocation;
  String stopTypes = railStoptypes;
  NearestStationResponse? nearestData;
  String nearestQuery = '';
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    determinePosition();
  }

  @override
  void reassemble() {
    super.reassemble();
    determinePosition();
  }

  void fetchNearestStations(String query) async {
    setState(() {
      nearestData = null;
    });

    print(query);
    final response = await http.get(Uri.parse(query));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final data = NearestStationResponse.fromJson(jsonDecode(response.body));

      setState(() {
        nearestData = data;
        nearestQuery = query;
      });
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  getNearestStations() async {
    if (currentLocation == null) {
      return;
    }

    String query =
        'https://api.tfl.gov.uk/StopPoint/?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&stopTypes=$stopTypes&radius=2000';

    if (nearestQuery != query || nearestData == null) {
      fetchNearestStations(query);
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  void determinePosition() async {
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
    if (pos != null) {
      setState(() {
        currentLocation = pos;
      });
    }

    Geolocator.getPositionStream().listen((Position? position) {
      if (position != null) {
        setState(() {
          currentLocation = position;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0 && stopTypes != railStoptypes) {
        setState(() {
          stopTypes = railStoptypes;
          tabIndex = index;
        });
      } else if (index == 1 && stopTypes != busStoptypes) {
        setState(() {
          stopTypes = busStoptypes;
          tabIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    getNearestStations();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearest Station'),
          backgroundColor: Colors.deepOrange,
        ),
        body: Center(
          child: nearestData != null
              ? ListView.builder(
                  itemCount:
                      nearestData != null ? nearestData!.stations.length : 0,
                  itemBuilder: (_, index) {
                    return StationCard(
                      station: nearestData!.stations[index],
                      index: index,
                    );
                  },
                )
              : const CircularProgressIndicator(),
        ),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.refresh),
            backgroundColor: Colors.deepOrange,
            onPressed: () async {
              determinePosition();
            }),
        bottomNavigationBar: BottomNavigationBar(
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
          currentIndex: tabIndex,
          selectedItemColor: Colors.deepOrange,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
