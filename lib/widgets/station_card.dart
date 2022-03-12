import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../util.dart';
import '../api/arrivals.dart';
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

class StationCard extends StatefulWidget {
  final StationSummary station;
  final int index;

  const StationCard(this.station, this.index);

  @override
  _StationCardState createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  ArrivalsResponse? arrivalsData;
  String arrivalsQuery = '';
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

  void fetchArrivals(String query) async {
    setState(() {
      arrivalsData = null;
    });

    print('Fetching arrivals: $query');
    final response = await http.get(Uri.parse(query));

    if (response.statusCode == 200) {
      final data = ArrivalsResponse.fromJson(jsonDecode(response.body));

      setState(() {
        arrivalsData = data;
      });
    } else {
      print('${response.statusCode} - ${response.reasonPhrase}');
      throw Exception('Failed to load nearest stations');
    }
  }

  getArrivals() async {
    String query =
        'https://api.tfl.gov.uk/StopPoint/${widget.station.id}/arrivals';

    if (arrivalsQuery != query) {
      fetchArrivals(query);
      setState(() {
        arrivalsQuery = query;
      });
    }
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
            color: line.color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
      );
    }
    return lineCards;
  }

  Widget renderArrival(Arrival arrival) {
    int minutes = (arrival.timeToStation / 60.0).round();
    return Row(
      children: [
        Container(
          width: 24,
          child: Text(
            arrival.lineName[0],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
          decoration: BoxDecoration(
            color: getLineColor(arrival.lineId, arrival.modeName),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Text(arrival.destinationId == widget.station.id
                ? 'Outbound'
                : arrival.towards),
          ),
        ),
        Text(minutes == 0 ? 'Now' : '$minutes min'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = modeToIcon[widget.station.lines.isNotEmpty
            ? widget.station.lines[0].mode
            : widget.station.modes[0]] ??
        const Icon(Icons.directions_bus_filled_outlined, size: 40);
    List<Widget> children = [];

    if (widget.index == 0) {
      getArrivals();

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
        ListTile(
          leading: icon,
          title: Text(widget.station.name),
          subtitle:
              Text('${(widget.station.distance / 1000).toStringAsFixed(1)} km'),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 1000, minHeight: 0),
          child: arrivalsData != null
              ? ListView.separated(
                  // to go back to listing arrivals over the next 20 mins
                  // itemCount: arrivalsData?.arrivals
                  //         .where((a) => a.timeToStation < 1200)
                  //         .length ??
                  //     0,
                  itemCount: min(arrivalsData?.arrivals.length ?? 0, 5),
                  itemBuilder: (_, index) {
                    Arrival arrival = arrivalsData!.arrivals[index];
                    return renderArrival(arrival);
                  },
                  separatorBuilder: (_, index) => const Divider(),
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shrinkWrap: true,
                )
              : const CircularProgressIndicator(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Wrap(
            children: generateLineCards(widget.station),
            spacing: 2,
            runSpacing: 2,
          ),
        )
      ];
    } else {
      children = [
        ListTile(
          leading: icon,
          title: Text(widget.station.name),
          subtitle:
              Text('${(widget.station.distance / 1000).toStringAsFixed(1)} km'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Wrap(
            children: generateLineCards(widget.station),
            verticalDirection: VerticalDirection.up,
            spacing: 2,
            runSpacing: 2,
          ),
        )
      ];
    }

    return Card(
      margin: EdgeInsets.fromLTRB(8, widget.index == 0 ? 0 : 16, 8, 8),
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
      elevation: max(8 / (widget.index + 1), 1),
    );
  }
}
