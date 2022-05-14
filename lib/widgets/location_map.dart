import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMap extends StatefulWidget {
  final CameraPosition cameraPosition;
  final Set<Marker> markers;
  final Position? currentLocation;

  const LocationMap(this.cameraPosition, this.markers, this.currentLocation);

  @override
  _LocationMapState createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) async {
    controller.setMapStyle(
        '[{"featureType": "poi", "stylers": [{"visibility": "off"}]}]');

    // zoom out of station coordinate until current location is visible on the map
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

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      myLocationEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      myLocationButtonEnabled: false,
      initialCameraPosition: widget.cameraPosition,
      markers: widget.markers,
    );
  }
}
