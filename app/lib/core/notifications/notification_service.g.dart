// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationServiceHash() =>
    r'399c7a645db475513281fc87cb3849d211b400a8';

/// Sets up notification rendering - Firebase Messaging gives us the
/// payload, `flutter_local_notifications` paints it. Channel id matches
/// what the push-notifier service sends to.
///
/// Background message delivery is handled by the FCM SDK + system tray
/// directly. Foreground delivery on Android shows nothing by default, so
/// we display via the local-notifications plugin AND invalidate the
/// completion providers so chips update without a refresh.
///
/// Also observes app lifecycle - on resume (coming back from background)
/// we re-invalidate today's completions to catch up on any pushes the OS
/// delivered while we were paused.
///
/// Copied from [notificationService].
@ProviderFor(notificationService)
final notificationServiceProvider = Provider<NotificationService>.internal(
  notificationService,
  name: r'notificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationServiceRef = ProviderRef<NotificationService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
