import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
  Position? currentLocation;
  String stopTypes = railStoptypes;
  String? currentLeadStationId;
  int tabIndex = 0;
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    // futureNearestStationResponse = fetchNearestStations();
    determinePosition();
  }

  @override
  void reassemble() {
    super.reassemble();
    determinePosition();
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
      final data = NearestStationResponse.fromJson(jsonDecode(response.body));
      print(
          '${currentLeadStationId != null} ${data.stations.length > 0} ${data.stations[0].id != currentLeadStationId}');
      if (currentLeadStationId != null &&
          data.stations.length > 0 &&
          data.stations[0].id != currentLeadStationId) {
        mapController.animateCamera(CameraUpdate.newLatLng(
            (LatLng(data.stations[0].latitude, data.stations[0].longitude))));
      } else if (currentLeadStationId == null) {
        setState(() {
          currentLeadStationId = data.stations[0].id;
        });
      }

      return data;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
                              SizedBox(
                                height: 150.0,
                                child: GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  myLocationEnabled: true,
                                  mapToolbarEnabled: false,
                                  rotateGesturesEnabled: false,
                                  scrollGesturesEnabled: false,
                                  zoomControlsEnabled: false,
                                  zoomGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  myLocationButtonEnabled: false,
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                        station.latitude, station.longitude),
                                    zoom: 14.0,
                                  ),
                                  markers: <Marker>{
                                    Marker(
                                      markerId: MarkerId(station.id),
                                      position: LatLng(
                                          station.latitude, station.longitude),
                                    ),
                                  },
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.subway),
                                title: Text(station.name),
                                subtitle: Text(
                                    '${(station.distance / 1000).toStringAsFixed(1)} km'),
                              ),
                            ],
                          ),
                          elevation: 4.0,
                        );
                      } else {
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
                          elevation: 2.0,
                        );
                      }
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
