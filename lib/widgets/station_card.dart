import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/nearest.dart';
import '../widgets/arrivals_list.dart';

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

class StationCard extends StatefulWidget {
  final StationSummary station;
  final int index;
  final Position? currentLocation;

  const StationCard(this.station, this.index, this.currentLocation);

  @override
  _StationCardState createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) async {
    controller.setMapStyle(
        '[{"featureType": "poi", "stylers": [{"visibility": "off"}]}]');

    // zoom out of station coordinate until current locatioon is visible on the map
    while (widget.currentLocation != null &&
        !(await controller.getVisibleRegion()).contains(LatLng(
            widget.currentLocation!.latitude,
            widget.currentLocation!.longitude))) {
      await controller.animateCamera(CameraUpdate.zoomOut());
    }

    setState(() {
      mapController = controller;
    });
  }

  List<Material> generateLineCards(StationSummary station) {
    List<Material> lineCards = [];
    for (final line in station.lines) {
      lineCards.add(
        Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
            decoration: BoxDecoration(
              color: line.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Text(
              line.name,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return lineCards;
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = modeToIcon[widget.station.lines.isNotEmpty
            ? widget.station.lines[0].mode
            : (widget.station.modes.isNotEmpty
                ? widget.station.modes[0]
                : '')] ??
        const Icon(Icons.directions_bus_filled_outlined, size: 40);

    return Container(
      decoration: widget.index != 0
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFBCBCBC),
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: icon,
              tileColor: Colors.white,
              title: Text(widget.station.name),
              subtitle: Text(
                  '${(widget.station.distance / 1000).toStringAsFixed(1)} km'),
            ),
          ),
          widget.index != 0
              ? const SizedBox(height: 0)
              : ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 1000, minHeight: 0),
                  child: AnimatedSize(
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 500),
                    alignment: Alignment.topCenter,
                    child: ArrivalsList(widget.station, 5),
                  ),
                ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Wrap(
              children: generateLineCards(widget.station),
              verticalDirection: VerticalDirection.up,
              spacing: 2,
              runSpacing: 2,
            ),
          )
        ],
      ),
    );
  }
}
