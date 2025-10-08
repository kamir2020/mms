class localRiverLocation {

  final int id;
  final String stationID;
  final String stateID;
  final String basinName;
  final String riverName;
  final String latitude;
  final String longitude;

  localRiverLocation({required this.id,
    required this.stationID,
    required this.stateID,
    required this.basinName,
    required this.riverName,
    required this.latitude,
    required this.longitude,
  });

  factory localRiverLocation.fromMap(Map<String, dynamic> map) {
    return localRiverLocation(
        id: map['id'],
        stationID: map['stationID'],
        stateID: map['stateID'],
        basinName: map['basinName'],
        riverName: map['riverName'],
        latitude: map['latitude'],
        longitude: map['longitude']);
  }


}