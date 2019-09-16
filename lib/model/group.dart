class Group {
  final String uid;
  final String displayName;
  final double latitude;
  final double longitude;
  final bool isCreator;

  const Group({this.uid, this.displayName, this.latitude, this.longitude, this.isCreator});

  factory Group.fromMap(String id, Map<String, dynamic> data, [bool isCreator = false]) {
    return Group(
      uid: id,
      displayName: data['name'],
      latitude: data['location']?.latitude,
      longitude: data['location']?.longitude,
      isCreator: isCreator,
    );
  }
}