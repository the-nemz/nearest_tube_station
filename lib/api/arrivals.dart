class ArrivalsResponse {
  final List<Arrival> arrivals;

  const ArrivalsResponse({
    required this.arrivals,
  });

  factory ArrivalsResponse.fromJson(List<dynamic> json) {
    List<Arrival> arrivals = [];
    for (final a in json) {
      arrivals.add(Arrival(
        id: a['id'],
        platformName: a['platformName'],
        destinationId: a['destinationNaptanId'],
        towards: a['towards'],
        timeToStation: a['timeToStation'],
        lineId: a['lineId'],
        lineName: a['lineName'],
        modeName: a['modeName'],
      ));
    }

    arrivals.sort((a, b) => a.timeToStation - b.timeToStation);

    return ArrivalsResponse(
      arrivals: arrivals,
    );
  }
}

class Arrival {
  final String id;
  final String platformName;
  final String destinationId;
  final String towards;
  final int timeToStation;
  final String lineId;
  final String lineName;
  final String modeName;

  const Arrival({
    required this.id,
    required this.platformName,
    required this.destinationId,
    required this.towards,
    required this.timeToStation,
    required this.lineId,
    required this.lineName,
    required this.modeName,
  });
}
