import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/nearest.dart';
import '../widgets/station_card.dart';
import '../widgets/station_page.dart';

class ResultsPanel extends StatefulWidget {
  final ScrollController controller;
  final NearestStationResponse? nearestData;
  final int numShown;
  final Position? currentLocation;

  const ResultsPanel(
      this.controller, this.nearestData, this.numShown, this.currentLocation);

  @override
  _ResultsPanelState createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel> {
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
  }

  Widget buildDragBar() => Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return widget.nearestData?.stations.isNotEmpty ?? false
        ? Column(
            children: [
              const SizedBox(height: 12),
              buildDragBar(),
              Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(0.0),
                    controller: widget.controller,
                    itemCount: widget.nearestData?.stations.length ?? 0,
                    itemBuilder: (_, index) {
                      return AnimatedOpacity(
                        opacity: index < widget.numShown ? 1.0 : 0.0,
                        curve: Curves.easeInOut,
                        duration: const Duration(milliseconds: 500),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StationPage(
                                    widget.nearestData!.stations[index],
                                    widget.currentLocation),
                              ),
                            );
                          },
                          child: StationCard(
                              widget.nearestData!.stations[index],
                              index,
                              widget.currentLocation),
                        ),
                      );
                    }),
              ),
            ],
          )
        : widget.nearestData != null
            ? const Text('There are no stations nearby.')
            : const CircularProgressIndicator();
  }
}
