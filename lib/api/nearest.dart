import 'package:flutter/material.dart';

import '../util.dart';

const stopTypeToMode = {
  'NaptanRailStation': ['national-rail', 'overground'],
  'NaptanMetroStation': ['tube'],
  'NaptanPublicBusCoachTram': ['bus'],
};

class NearestStationResponse {
  final int pageSize;
  final int total;
  final int page;
  final List<StationSummary> stations;

  const NearestStationResponse({
    required this.pageSize,
    required this.total,
    required this.page,
    required this.stations,
  });

  factory NearestStationResponse.fromJson(Map<String, dynamic> json) {
    List<StationSummary> stations = [];
    for (final s in json['stopPoints']) {
      Map<String, String> validLineIdsToMode = {};
      final stopTypes = stopTypeToMode[s['stopType']];
      for (final lg in s['lineModeGroups']) {
        if (stopTypes != null &&
            stopTypes.contains(lg['modeName']) &&
            lg.containsKey('lineIdentifier')) {
          for (final validLineId in lg['lineIdentifier']) {
            validLineIdsToMode[validLineId] = lg['modeName'];
          }
        }
      }

      List<LineSummary> lines = [];
      for (final l in s['lines']) {
        if (validLineIdsToMode.containsKey(l['id'])) {
          lines.add(LineSummary(
            id: l['id'],
            name: l['name'],
            mode: validLineIdsToMode[l['id']]!,
          ));
        }
      }

      stations.add(StationSummary(
        id: s['id'],
        name: s['commonName'].replaceAll('Underground Station', '').trim(),
        stopType: s['stopType'],
        distance: s['distance'],
        latitude: s['lat'],
        longitude: s['lon'],
        modes: [...s['modes']],
        lines: lines,
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

class StationSummary {
  final String id;
  final String name;
  final String stopType;
  final double distance;
  final double latitude;
  final double longitude;
  final List<String> modes;
  final List<LineSummary> lines;

  const StationSummary({
    required this.id,
    required this.name,
    required this.stopType,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.modes,
    required this.lines,
  });
}

class LineSummary {
  final String id;
  final String name;
  final String mode;
  final Color color;

  LineSummary({
    required this.id,
    required this.name,
    required this.mode,
  }) : color = getLineColor(id, mode);
}
