import 'package:go_smoke/model/group.dart';

class User {
  final String uid;
  final String displayName;
  final String photoUrl;
  final List<Group> groups;

  const User({
    this.uid,
    this.displayName,
    this.photoUrl,
    this.groups,
  });

  factory User.fromMap(String uid, Map<String, dynamic> map) {
    return User(
      uid: uid,
      displayName: map['n'],
      photoUrl: map['p'],
      groups: map['g'] != null ? List.from(map['g']).map((s) => Group.fromMap(s, {})).toList(growable: false) : List<Group>(),
    );
  }
}
