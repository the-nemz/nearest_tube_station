import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<NearestStationResponse> futureNearestStationResponse;

  @override
  void initState() {
    // TODO: query TfL
    super.initState();
    futureNearestStationResponse = fetchNearestStations();
  }

  Future<NearestStationResponse> fetchNearestStations() async {
    final response = await http.get(Uri.parse(
        'https://api.tfl.gov.uk/StopPoint/?lat=51.463&lon=-0.114&stopTypes=NaptanMetroStation&radius=2000'));

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearest Tube Station'),
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: FutureBuilder<NearestStationResponse>(
            future: futureNearestStationResponse,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // return Text('${snapshot.data!.stations[0].name}');
                return ListView.builder(
                  itemCount: snapshot.data!.stations.length,
                  itemBuilder: (_, index) {
                  return Text( snapshot.data!.stations[index].name);
                });
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
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
        ),
      ),
    );
  }
}

class NearestStationResponse {
  final int pageSize;
  final int total;
  final int page;
  final List<StationResponse> stations;

  const NearestStationResponse({
    required this.pageSize,
    required this.total,
    required this.page,
    required this.stations,
  });

  factory NearestStationResponse.fromJson(Map<String, dynamic> json) {
    List<StationResponse> stations = [];
    for (final s in json['stopPoints']) {
      stations.add(StationResponse(
        id: s['id'],
        name: s['commonName'],
        distance: s['distance'],
        latitude: s['lat'],
        longitude: s['lon'],
      ));
    }

    return NearestStationResponse(
      pageSize: json['pageSize'],
      total: json['total'],
      page: json['page'],
      stations: stations,
    );
  }
}

class StationResponse {
  final String id;
  final String name;
  final double distance;
  final double latitude;
  final double longitude;

  const StationResponse({
    required this.id,
    required this.name,
    required this.distance,
    required this.latitude,
    required this.longitude,
  });
}
