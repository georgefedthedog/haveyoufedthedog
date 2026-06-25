import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/pocketbase_client.dart';
import '../auth/auth_controller.dart';
import '../household/current_household_controller.dart';
import 'subject.dart';
import 'subjects_controller.dart';

part 'subject_actions.g.dart';

/// Side-effect provider exposing imperative subject operations.
@Riverpod(keepAlive: true)
SubjectActions subjectActions(Ref ref) => SubjectActions(ref);

class SubjectActions {
  final Ref _ref;
  SubjectActions(this._ref);

  Future<String> _currentUserId() async {
    final auth = await _ref.read(authControllerProvider.future);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Operation requires a signed-in user.');
    }
    return userId;
  }

  Future<String> _currentHouseholdId() async {
    final hh = await _ref.read(currentHouseholdControllerProvider.future);
    if (hh == null) {
      throw StateError('No current household selected.');
    }
    return hh.id;
  }

  Future<Subject> createSubject({
    required String name,
    String? icon,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final userId = await _currentUserId();
    final householdId = await _currentHouseholdId();

    final rec = await pb.collection('subjects').create(body: {
      'household': householdId,
      'name': name,
      'icon': icon ?? '',
      'sort_order': 0,
      'created_by': userId,
    });
    _ref.invalidate(subjectsControllerProvider);
    return Subject(rec);
  }

  Future<Subject> updateSubject(
    String id, {
    String? name,
    String? icon,
    bool clearIcon = false,
  }) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (clearIcon) {
      body['icon'] = '';
    } else if (icon != null) {
      body['icon'] = icon;
    }
    final rec = await pb.collection('subjects').update(id, body: body);
    _ref.invalidate(subjectsControllerProvider);
    return Subject(rec);
  }

  /// Records that an NFC tag has been written for this subject (stores the
  /// written URL in `nfc_tag_id`). Drives the "tag linked" indicator. Note
  /// this means "a tag was written," not "a working tag exists right now."
  Future<void> setNfcTag(String id, String url) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('subjects').update(id, body: {'nfc_tag_id': url});
    _ref.invalidate(subjectsControllerProvider);
  }

  /// Forgets the written-tag marker (clears `nfc_tag_id`).
  Future<void> clearNfcTag(String id) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('subjects').update(id, body: {'nfc_tag_id': ''});
    _ref.invalidate(subjectsControllerProvider);
  }

  Future<void> deleteSubject(String id) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    await pb.collection('subjects').delete(id);
    _ref.invalidate(subjectsControllerProvider);
  }

  /// Looks up a subject by id, scoped to the current household. Returns null
  /// if it doesn't exist, isn't accessible, or belongs to another household
  /// (so an NFC tag from a household you're not in won't log anywhere).
  Future<Subject?> findById(String id) async {
    final pb = await _ref.read(pocketbaseClientProvider.future);
    final householdId = await _currentHouseholdId();
    try {
      final rec = await pb.collection('subjects').getOne(id);
      final subject = Subject(rec);
      return subject.householdId == householdId ? subject : null;
    } catch (_) {
      return null;
    }
  }

}
