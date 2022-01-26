import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  String? currentLeadStationId;
  int tabIndex = 0;
  late GoogleMapController mapController;

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

  void getLocationData() async {
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
