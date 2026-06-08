import 'package:pocketbase/pocketbase.dart';

/// Thin wrapper around a PocketBase `subjects` record.
class Subject {
  final RecordModel record;
  const Subject(this.record);

  String get id => record.id;
  String get householdId => record.data['household'] as String;
  String get name => record.data['name'] as String;

  String? get icon {
    final v = record.data['icon'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  String? get nfcTagId {
    final v = record.data['nfc_tag_id'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  int get sortOrder => (record.data['sort_order'] as num?)?.toInt() ?? 0;
}
