import 'package:flutter/material.dart';
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

class StationPage extends StatefulWidget {
  final StationSummary station;

  const StationPage(this.station);

  @override
  _StationPageState createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> {
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      controller.setMapStyle(
          '[{"featureType": "poi", "stylers": [{"visibility": "off"}]}]');
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
                borderRadius: const BorderRadius.all(Radius.circular(4))),
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
            : widget.station.modes[0]] ??
        const Icon(Icons.directions_bus_filled_outlined, size: 40);

    List<Widget> children = [
      Hero(
        tag: '${widget.station.id}-map',
        child: SizedBox(
          height: 300,
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
              target: LatLng(widget.station.latitude, widget.station.longitude),
              zoom: 14,
            ),
            markers: <Marker>{
              Marker(
                markerId: MarkerId(widget.station.id),
                position:
                    LatLng(widget.station.latitude, widget.station.longitude),
              ),
            },
          ),
        ),
      ),
      Hero(
        tag: widget.station.id,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: icon,
                title: Text(widget.station.name),
                subtitle: Text(
                    '${(widget.station.distance / 1000).toStringAsFixed(1)} km'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Wrap(
                children: generateLineCards(widget.station),
                spacing: 2,
                runSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 16.0),
        child: AnimatedSize(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 1000),
          alignment: Alignment.topCenter,
          child: ArrivalsList(widget.station),
        ),
      ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
