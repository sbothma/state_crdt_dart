import 'package:uuid/uuid.dart';

abstract class StateCRDT {
  /// Date this crdt was created (fixed)
  DateTime created_at;

  /// Date this crdt was updated
  DateTime updated_at;
  DateTime first_seen;

  int version;

  String state_hash;

  Set<String> _archive_hashes = {};
  Set<String> _draft_hashes = {};
  Set<String> _removed_hashes = {};
  Set<String> _state_hashes = {};

  // Optional
  Map<String, StateCRDT> previous = {};

  /// Merge two CRDT items using "Last Writer Wins"
  /// Consider checking this.hasMerged(b) first
  StateCRDT merge(StateCRDT b) {
    if (this == null) return b;
    if (b == null) return this;
    if (updated_at.isAfter(b.updated_at)) {
      return _merge(this, b);
    } else {
      return _merge(b, this);
    }
  }

  /// Check if a state_hash has been merged with this version
  /// Use only after checking if state_hashes don't match
  bool hasMerged(String state_hash) => _state_hashes.contains(this.state_hash);

  /// Checks if an item is (currently) marked as archived
  bool get isArchived => _archive_hashes.contains(this.state_hash);

  /// Checks if an item is (currently) marked as a draft
  bool get isDraft => _draft_hashes.contains(this.state_hash);

  /// Checks if an item is (currently) marked as removed
  bool get isRemoved => _removed_hashes.contains(this.state_hash);

  /// Mark an item as archived (until state hash is refreshed)
  void markArchived() {
    if (this.state_hash == null) return;
    if (!_archive_hashes.contains(this.state_hash)) {
      _archive_hashes.add(state_hash);
    }
  }

  /// Mark an item as a draft (until state hash is refreshed)
  void markDraft() {
    if (this.state_hash == null) return;
    if (!_draft_hashes.contains(this.state_hash)) {
      _draft_hashes.add(state_hash);
    }
  }

  /// Mark an item as removed (until state hash is refreshed)
  void markRemoved() {
    if (this.state_hash == null) return;
    if (!_removed_hashes.contains(this.state_hash)) {
      _removed_hashes.add(state_hash);
    }
  }

  /// Refresh the current state_hash of the CRDT
  ///
  /// Call this method to reset an items archived, removed, and draft states.
  ///
  ///   Usage:
  ///
  ///
  void refreshStateHash({
    bool archived,
    bool draft,
    bool removed,
    DateTime updated_at,
  }) {
    _state_hashes.add(state_hash);
    state_hash = make_id();
    if (archived ?? this.isArchived) this.markArchived();
    if (draft ?? this.isDraft) this.markDraft();
    if (removed ?? this.isRemoved) this.markRemoved();
    this.updated_at = updated_at ?? DateTime.now(); // Test with and without
  }

  String make_id() => Uuid().v4();

  /// Initialize state crdt properties
  ///
  /// Usage
  ///
  void init() {
    this.created_at = DateTime.now();
    this.updated_at = created_at;
    this.state_hash = make_id();
    this.previous ??= {};
  }

  /// Construct an instance from a json map-like structure
  ///
  ///   Usage:
  ///
  ///     Example.fromMap(Map json) {
  ///       super.fromMap(json);
  ///       this.id = json["id"];
  ///     }
  ///
  fromMap(Map m) {
    try {
      this.created_at =
          m["created_at"] != null ? DateTime.parse(m["created_at"]) : null;
      this.updated_at =
          m["updated_at"] != null ? DateTime.parse(m["updated_at"]) : null;
      this.first_seen = m["first_seen"] != null
          ? DateTime.parse(m["first_seen"])
          : DateTime.now();
      this.state_hash = m["state_hash"];
      this._archive_hashes = m["archive_hashes"] != null
          ? Set<String>.from(m["archive_hashes"])
          : <String>{};
      this._removed_hashes = m["removed_hashes"] != null
          ? Set<String>.from(m["removed_hashes"])
          : <String>{};
      this._draft_hashes = m["draft_hashes"] != null
          ? Set<String>.from(m["draft_hashes"])
          : <String>{};
      this._state_hashes = m["state_hashes "] != null
          ? Set<String>.from(m["state_hashes"])
          : <String>{};
    } catch (e) {
      print(e.toString());
    }
  }

  /// Export a Map with the required fields json encoded
  ///
  /// Usage
  ///   Map toMap() {
  ///     return {
  ///       "id": this.id,
  ///     }..addAll(super.toMap());
  ///   }
  ///
  Map toMap() {
    return {
      "created_at": dateString(this.created_at),
      "updated_at": dateString(this.updated_at),
      "first_seen": dateString(this.first_seen),
      "previous": this.previous,
      "state_hash": this.state_hash,
      "archive_hashes": this._archive_hashes.toList(),
      "removed_hashes": this._removed_hashes.toList(),
      "draft_hashes": this._draft_hashes.toList(),
      "state_hashes": this._state_hashes.toList(),
    };
  }

  /// Encode a date-time string in json format
  static String dateString(DateTime d) {
    if (d == null) d = DateTime.now();
    return d?.toIso8601String()?.substring(0, 19)?.replaceFirst('T', ' ');
  }

  StateCRDT _merge(StateCRDT a, StateCRDT b) {
    if (b.previous != null && b.previous != {}) a.previous.addAll(b.previous);
    b.previous = {};
    if (b._archive_hashes != null) a._archive_hashes.addAll(b._archive_hashes);
    b._archive_hashes = {};
    if (b._removed_hashes != null) a._removed_hashes.addAll(b._removed_hashes);
    b._removed_hashes = {};
    if (b._draft_hashes != null) a._draft_hashes.addAll(b._draft_hashes);
    b._draft_hashes = {};
    a.previous[b.state_hash] = b;
    return a;
  }

  static String toDateString(DateTime d) {
    return d?.toIso8601String()?.substring(0, 19)?.replaceFirst('T', ' ');
  }
}
