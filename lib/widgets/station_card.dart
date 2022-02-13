import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/nearest.dart';

const modeToIcon = {
  'national-rail': Image(
    image: AssetImage('assets/nationalrail.png'),
    width: 40,
  ),
  'overground': Image(
    image: AssetImage('assets/overground.png'),
    width: 40,
  ),
  'tube': Image(
    image: AssetImage('assets/underground.png'),
    width: 40,
  ),
  'bus': Image(
    image: AssetImage('assets/buses.png'),
    width: 40,
  ),
};

class StationCard extends StatelessWidget {
  StationCard({
    Key? key,
    required this.station,
    required this.index,
  }) : super(key: key);

  final StationSummary station;
  final int index;

  void _onMapCreated(GoogleMapController controller) {
    // not yet needed
  }

  List<Container> generateLineCards(StationSummary station) {
    List<Container> lineCards = [];
    for (final line in station.lines) {
      lineCards.add(Container(
        child: Text(
          line.name,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          // color: Colors.white,
          color: line.color != null ? line.color! : Colors.blue,
        ),
      ));
    }
    return lineCards;
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = modeToIcon[station.lines.isNotEmpty
            ? station.lines[0].mode
            : station.modes[0]] ??
        const Icon(Icons.directions_bus_filled_outlined, size: 40);

    if (index == 0) {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  target: LatLng(station.latitude, station.longitude),
                  zoom: 14.0,
                ),
                markers: <Marker>{
                  Marker(
                    markerId: MarkerId(station.id),
                    position: LatLng(station.latitude, station.longitude),
                  ),
                },
              ),
            ),
            ListTile(
              leading: icon,
              title: Text(station.name),
              subtitle:
                  Text('${(station.distance / 1000).toStringAsFixed(1)} km'),
            ),
            Wrap(
              children: generateLineCards(station),
              spacing: 10,
            )
          ],
        ),
        elevation: 4.0,
      );
    } else {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              leading: icon,
              title: Text(station.name),
              subtitle:
                  Text('${(station.distance / 1000).toStringAsFixed(1)} km'),
            ),
            Wrap(
              children: generateLineCards(station),
              spacing: 10,
            )
          ],
        ),
        elevation: 2.0,
      );
    }
  }
}
