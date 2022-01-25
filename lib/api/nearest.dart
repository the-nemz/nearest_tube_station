class NearestStationResponse {
  final int pageSize;
  final int total;
  final int page;
  final List<StationResponse> stations;

  const NearestStationResponse({
    required this.pageSize,
    required this.total,
    required this.page,
    required this.stations,
  });

  factory NearestStationResponse.fromJson(Map<String, dynamic> json) {
    List<StationResponse> stations = [];
    for (final s in json['stopPoints']) {
      stations.add(StationResponse(
        id: s['id'],
        name: s['commonName'],
        distance: s['distance'],
        latitude: s['lat'],
        longitude: s['lon'],
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

class StationResponse {
  final String id;
  final String name;
  final double distance;
  final double latitude;
  final double longitude;

  const StationResponse({
    required this.id,
    required this.name,
    required this.distance,
    required this.latitude,
    required this.longitude,
  });
}
