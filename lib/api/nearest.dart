import 'package:flutter/material.dart';

const nationalRailColor = Color(0xFFE11B22);

const lineToColor = {
  'bakerloo': Color(0xFFA45A2A),
  'central': Color(0xFFDA291C),
  'circle': Color(0xFFFFCD00),
  'district': Color(0xFF007A33),
  'hammersmith-city': Color(0xFFE89CAE),
  'jubilee': Color(0xFF7C878E),
  'metropolitan': Color(0xFF840B55),
  'northern': Color(0xFF2D2926),
  'piccadilly': Color(0xFF10069F),
  'victoria': Color(0xFF00A3E0),
  'waterloo-city': Color(0xFF6ECEB2),
  'london-overground': Color(0xFFE87722),
};

// DLR #00AFAD
// tflrail #0019A8
// tram #00BD19
// londontrams #00BD19

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
        if (stopTypes != null && stopTypes.contains(lg['modeName']) && lg.containsKey('lineIdentifier')) {
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
        name: s['commonName'],
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
  final Color? color;

  LineSummary({
    required this.id,
    required this.name,
    required this.mode,
  }) : color = mode == 'national-rail' ? nationalRailColor : lineToColor[id];
}
