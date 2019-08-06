import 'package:state_crdt/state_crdt.dart';
import 'dart:convert';

class Something extends StateCRDT {
  String name;
  String id;

  Something({this.name}) {
    super.init();
    this.id = make_id();
  }

  Map toMap() {
    return {
      'id': this.id,
      'name': this.name,
    }..addAll(super.toMap());
  }

  Something.fromMap(Map json) {
    super.fromMap(json);
    this.id = json['id'];
    this.name = json['name'];
  }

  static Something fromJson(String string) {
    return Something.fromMap(json.decode(string));
  }

  String toJson() => json.encode(this.toMap());
}

main() {
  // Cloud-peer sends:
  var awesome = Something(name: 'awesome');
  String serialized = awesome.toJson();

  // Client A receives, then transforms:
  var one = Something.fromJson(serialized)..markArchived();

  // Client B receives, then transforms:
  var two = Something.fromJson(serialized)
    ..name = 'renamed'
    ..markDraft();

  // Clients exchange json encoded versions:
  String one_string = one.toJson();
  String two_string = two.toJson();

  // Merging should produce (eventually) consistant state:
  var three = Something.fromJson(two_string)
    ..merge(Something.fromJson(one_string));

  assert(three.isArchived);
  assert(three.isDraft);
  assert(three.name == 'renamed');
  print('merged!');
}
