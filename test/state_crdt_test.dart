import 'package:state_crdt/state_crdt.dart';
import 'package:test/test.dart';
import 'dart:convert';

class Example extends StateCRDT {
  String id;

  Example() {
    super.init();
    this.id = make_id();
  }

  Example.withId() {
    this.id = make_id();
  }

  Example.withInit() {
    super.init();
  }

  Map toMap() {
    return {
      'id': this.id,
    }..addAll(super.toMap());
  }

  Example.fromMap(Map json) {
    super.fromMap(json);
    this.id = json['id'];
  }

  // Deserialize
  static Example fromJson(String string) {
    return Example.fromMap(json.decode(string));
  }

  // Serialize
  String toJson() => json.encode(this.toMap());
}

void main() {
  group("StateCRDT", () {
    test("merge", () {
      var e = Example();
      String init = e.toJson();
      Example b = Example.fromJson(init);
      b.markArchived();
      assert(b.isArchived);
      assert(!b.isRemoved);
      Example c = Example.fromJson(init);
      c.markRemoved();
      assert(c.isRemoved);
      assert(!c.isArchived);
      b.merge(c);
      assert(!b.isArchived);
      b = b.merge(c);
      assert(b.isArchived);
      assert(b.isRemoved);
    });

    test("#super.init", () {
      var i = Example.withInit();
      assert(i.created_at != null);
    });

    test("extends", () {
      Example();
    });

    test("markArchived() and isArchived", () {
      Example a = Example();
      a.markArchived();
      assert(a.isArchived);
    });

    test("markDraft() and isDraft", () {
      Example a = Example();
      a.markDraft();
      assert(a.isDraft);
    });

    test("markRemoved() and isRemoved", () {
      Example a = Example();
      a.markRemoved();
      assert(a.isRemoved);
    });

    test("#refreshStateHash", () {
      Example a = Example();
      a.markArchived();
      a.markRemoved();
      a.markDraft();
      assert(a.isArchived);
      assert(a.isRemoved);
      assert(a.isDraft);
      a.refreshStateHash();
      assert(!a.isArchived);
      assert(!a.isRemoved);
      assert(!a.isDraft);
    });

    test("refreshStateHash(removed: true)", () {
      Example a = Example();
      a.markArchived();
      a.markRemoved();
      assert(a.isArchived);
      assert(a.isRemoved);
      a.refreshStateHash(removed: a.isRemoved);
      assert(a.isRemoved);
      assert(!a.isArchived);
    });

    test("#make_id", () {
      Example a = Example.withId();
      assert(a.id != null);
    });

    test("#super.toMap", () {
      var e = Example();
      assert(e.toMap()["created_at"] != null);
      assert(e.toMap()["id"] != null);
    });

    test("#super.fromMap", () {
      Map i = {"created_at": "2000-01-01 00:00:00"};
      var e = Example.fromMap(i);
      assert(e.created_at != null);
    });

    test("#dateString", () {
      String dateString = "1969-07-20 20:18:04";
      assert(dateString == StateCRDT.dateString(DateTime.parse(dateString)));
    });
  });
}
