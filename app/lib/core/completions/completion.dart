import 'package:pocketbase/pocketbase.dart';

/// Where a completion came from. Mirrors the server-side `source` enum
/// on the `completions` collection.
enum CompletionSource {
  button,
  nfc,
  manual;

  static CompletionSource fromWire(String? raw) {
    switch (raw) {
      case 'nfc':
        return CompletionSource.nfc;
      case 'manual':
        return CompletionSource.manual;
      default:
        return CompletionSource.button;
    }
  }

  String get wire => name;
}

/// Thin wrapper around a PocketBase `completions` record.
class Completion {
  final RecordModel record;
  const Completion(this.record);

  String get id => record.id;
  String get subjectId => record.data['subject'] as String;

  String? get choreId {
    final v = record.data['chore'];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  DateTime get completedAt =>
      DateTime.parse(record.data['completed_at'] as String).toLocal();

  String get completedById => record.data['completed_by'] as String;

  String get sourceRaw => record.data['source'] as String;
  CompletionSource get source => CompletionSource.fromWire(sourceRaw);

  String? get notes {
    final v = record.data['notes'];
    return (v is String && v.isNotEmpty) ? v : null;
  }
}
