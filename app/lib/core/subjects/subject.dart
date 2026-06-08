/// A "Subject" — the thing chores are done to/for. A dog, a cat, a plant, a
/// child. Belongs to one household.
class Subject {
  final String id;
  final String householdId;
  final String name;
  final String? icon;
  final String? nfcTagId;
  final int sortOrder;

  const Subject({
    required this.id,
    required this.householdId,
    required this.name,
    this.icon,
    this.nfcTagId,
    this.sortOrder = 0,
  });
}
