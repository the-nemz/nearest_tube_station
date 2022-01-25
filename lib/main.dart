import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import 'api/nearest.dart';

const railStoptypes = 'NaptanMetroStation,NaptanRailStation';
const busStoptypes = 'NaptanPublicBusCoachTram';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // late Future<NearestStationResponse> futureNearestStationResponse;
  LocationData? currentLocation;
  String stopTypes = railStoptypes;
  int tabIndex = 0;

  @override
  void initState() {
    // TODO: query TfL
    super.initState();
    // futureNearestStationResponse = fetchNearestStations();
    getLocationData();
  }

  Future<NearestStationResponse?> fetchNearestStations() async {
    if (currentLocation == null) {
      return null;
    }

    final response = await http.get(Uri.parse(
        'https://api.tfl.gov.uk/StopPoint/?lat=${currentLocation!.latitude}&lon=${currentLocation!.longitude}&stopTypes=$stopTypes&radius=2000'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return NearestStationResponse.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  void getLocationData() async {
    print('currentLocation');
    print(currentLocation);
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    print(_locationData);
    setState(() {
      currentLocation = _locationData;
    });

    location.onLocationChanged.listen((LocationData curr) {
      print(curr);
      setState(() {
        currentLocation = curr;
      });
    });
  }

  void _onItemTapped(int index) {
    print(index);
    print('current $stopTypes');
    setState(() {
      if (index == 0 && stopTypes != railStoptypes) {
        print(railStoptypes);
        setState(() {
          stopTypes = railStoptypes;
          tabIndex = index;
        });
      } else if (index == 1 && stopTypes != busStoptypes) {
        print(busStoptypes);
        setState(() {
          stopTypes = busStoptypes;
          tabIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build current $stopTypes');
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearest Station'),
          backgroundColor: Colors.deepOrange,
        ),
        body: Center(
          child: FutureBuilder<NearestStationResponse?>(
            future: fetchNearestStations(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data!.stations.length,
                    itemBuilder: (_, index) {
                      StationResponse station = snapshot.data!.stations[index];

                      if (index == 0) {
                        return Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.subway),
                                title: Text(station.name),
                                subtitle: Text(
                                    '${(station.distance / 1000).toStringAsFixed(1)} km'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.subway),
                              title: Text(station.name),
                              subtitle: Text(
                                  '${(station.distance / 1000).toStringAsFixed(1)} km'),
                            ),
                          ],
                        ),
                      );
                    });
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.refresh),
            backgroundColor: Colors.deepOrange,
            onPressed: () {
              getLocationData();
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
