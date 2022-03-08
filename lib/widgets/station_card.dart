import 'dart:math';

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
      lineCards.add(
        Container(
          child: Text(
            line.name,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
          decoration: BoxDecoration(
            color: line.color != null ? line.color! : Colors.blue,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
      );
    }
    return lineCards;
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = modeToIcon[station.lines.isNotEmpty
            ? station.lines[0].mode
            : station.modes[0]] ??
        const Icon(Icons.directions_bus_filled_outlined, size: 40);

    List<Widget> children = [];
    if (index == 0) {
      children = [
        SizedBox(
          height: 150,
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
              zoom: 14,
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
          subtitle: Text('${(station.distance / 1000).toStringAsFixed(1)} km'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Wrap(
            children: generateLineCards(station),
            spacing: 2,
          ),
        )
      ];
    } else {
      children = [
        ListTile(
          leading: icon,
          title: Text(station.name),
          subtitle: Text('${(station.distance / 1000).toStringAsFixed(1)} km'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Wrap(
            children: generateLineCards(station),
            spacing: 2,
          ),
        )
      ];
    }

    return Card(
      margin: EdgeInsets.fromLTRB(8, index == 0 ? 0 : 16, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: max(8 / (index + 1), 1),
      // elevation: max(8.0 - (2 * index), 1),
    );
  }
}
