class StationAirInstall {
  final String id;
  final String refID;
  final String stationID;
  final String locationName;
  final String temp;
  final String timestamp;

  StationAirInstall({required this.id,required this.refID, required this.stationID,
    required this.locationName,required this.temp,required this.timestamp});

  factory StationAirInstall.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v) => v?.toString() ?? '';

    return StationAirInstall(
      id: asString(json['id']),
      refID: asString(json['refID']),
      stationID: asString(json['stationID']),
      locationName: asString(json['locationName']),
      temp: asString(json['temp']),
      timestamp: asString(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'refID': refID,
    'stationID': stationID,
    'locationName': locationName,
    'temp': temp,
    'timestamp': timestamp,
  };

  /*
  factory StationAirInstall.fromJson(Map<String, dynamic> json) {
    return StationAirInstall(
      id: json['id'],
      refID: json['refID'],
      stationID: json['stationID'],
      locationName: json['locationName'],
      temp: json['temp'],
      timestamp: json['timestamp'],
    );}
    */


}