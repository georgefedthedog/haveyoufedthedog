import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../completions/recent_completions_controller.dart';
import '../completions/today_completions_controller.dart';
import '../household/current_household_controller.dart';
import '../l10n/app_localizations_provider.dart';

part 'notification_service.g.dart';

/// Pinned in AndroidManifest.xml meta-data - must NEVER change (existing
/// installs and the worker both send to it). The user-visible name and
/// description are localized at init; re-creating the channel with the same
/// id just updates them, so a language change applies on the next launch.
const _channelId = 'chore_completions';

/// Sets up notification rendering - Firebase Messaging gives us the
/// payload, `flutter_local_notifications` paints it. Channel id matches
/// what the worker service sends to.
///
/// Background message delivery is handled by the FCM SDK + system tray
/// directly. Foreground delivery on Android shows nothing by default, so
/// we display via the local-notifications plugin AND invalidate the
/// completion providers so chips update without a refresh.
///
/// Also observes app lifecycle - on resume (coming back from background)
/// we re-invalidate today's completions to catch up on any pushes the OS
/// delivered while we were paused.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService(ref);

class NotificationService with WidgetsBindingObserver {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> init() async {
    final l10n = _ref.read(appLocalizationsProvider);
    final channel = AndroidNotificationChannel(
      _channelId,
      l10n.notifChannelName,
      description: l10n.notifChannelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    // iOS: don't prompt for permission here - FirebaseMessaging.requestPermission()
    // below is the single source of the notification-permission request.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tapping a notification: from background (onMessageOpenedApp) or from a
    // cold launch where the tap started the app (getInitialMessage).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    WidgetsBinding.instance.addObserver(this);
    _ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    // Ask for permission first so the prompt always appears - on iOS this
    // must not sit behind getInitialMessage, which can stall on APNs.
    await FirebaseMessaging.instance.requestPermission();

    // getInitialMessage waits on APNs registration on iOS and can hang
    // indefinitely. Cap it - a missed cold-launch tap route is far better
    // than a wedged init. (init() is off the first-frame path now, but the
    // timeout keeps a stall from silently swallowing the rest of setup.)
    final initial = await FirebaseMessaging.instance
        .getInitialMessage()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (initial != null) unawaited(_handleTap(initial));
  }

  /// Routes a tapped notification to where it's about: award pushes land on
  /// the Awards tab, completion/overdue pushes (which carry a `subjectId`)
  /// open that thing's page.
  ///
  /// Awaits the auth → household chain first so a cold launch from a tap
  /// doesn't push a route the redirect immediately bounces. A null
  /// household means signed out / nothing picked - the redirect already
  /// lands them correctly, so we leave navigation alone.
  Future<void> _handleTap(RemoteMessage message) async {
    final data = message.data;
    if (await _ref.read(currentHouseholdControllerProvider.future) == null) {
      return;
    }
    final router = _ref.read(appRouterProvider);

    switch (data['type']) {
      case 'award':
        router.go(Routes.historyTab);
      case 'subject':
        // Completion + overdue pushes name the subject they're about.
        final subjectId = data['subjectId'];
        if (subjectId is String && subjectId.isNotEmpty) {
          router.push(Routes.subjectDetail(subjectId));
        }
      // Any other / unknown type: no navigation - just bring the app to the
      // foreground where the user left it.
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    debugPrint('FCM foreground: ${notif?.title} / ${notif?.body}');

    _refresh(message.data['subjectId'] as String?);

    if (notif == null) return;
    final l10n = _ref.read(appLocalizationsProvider);
    _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.notifChannelName,
          channelDescription: l10n.notifChannelDesc,
          icon: 'ic_stat_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background pushes that landed while we were paused already updated
    // the server; refetch on resume so the UI catches up.
    if (state == AppLifecycleState.resumed) _refresh(null);
  }

  void _refresh(String? subjectId) {
    _ref.invalidate(todayCompletionsControllerProvider);
    if (subjectId != null) {
      _ref.invalidate(recentCompletionsControllerProvider(subjectId));
    }
  }
}
