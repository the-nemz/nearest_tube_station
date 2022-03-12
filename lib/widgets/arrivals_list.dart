import 'dart:convert';

import 'package:flutter/material.dart';
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

class ArrivalsList extends StatefulWidget {
  final StationSummary station;
  final int count;

  const ArrivalsList(this.station, [this.count = 0]);

  @override
  _ArrivalsListState createState() => _ArrivalsListState();
}

class _ArrivalsListState extends State<ArrivalsList> {
  ArrivalsResponse? arrivalsData;
  String arrivalsQuery = '';

  @override
  void initState() {
    super.initState();
  }

  // void fetchArrivals(String query) async {
  Future<ArrivalsResponse?> fetchArrivals() async {
    String query =
        'https://api.tfl.gov.uk/StopPoint/${widget.station.id}/arrivals';

    if (arrivalsQuery == query) {
      return arrivalsData;
    }

    setState(() {
      arrivalsQuery = query;
    });

    print('Fetching arrivals: $query');
    final response = await http.get(Uri.parse(query));

    if (response.statusCode == 200) {
      final data = ArrivalsResponse.fromJson(jsonDecode(response.body));

      setState(() {
        arrivalsData = data;
      });

      return data;
    } else {
      print('${response.statusCode} - ${response.reasonPhrase}');
      throw Exception('Failed to load nearest stations');
    }
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
    return FutureBuilder<ArrivalsResponse?>(
      future: fetchArrivals(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.separated(
            itemCount: widget.count != 0
                ? widget.count
                : arrivalsData?.arrivals
                        .where((a) => a.timeToStation < 1200)
                        .length ??
                    0,
            itemBuilder: (_, index) {
              Arrival arrival = snapshot.data!.arrivals[index];
              return renderArrival(arrival);
            },
            separatorBuilder: (_, index) => const Divider(),
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shrinkWrap: true,
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const SizedBox.shrink();
      },
    );
  }
}
