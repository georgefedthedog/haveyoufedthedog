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

part 'notification_service.g.dart';

const _channelId = 'chore_completions';
const _channelName = 'Chore completions';
const _channelDescription = 'When someone in your household logs a chore.';

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
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tapping a notification: from background (onMessageOpenedApp) or from a
    // cold launch where the tap started the app (getInitialMessage).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) unawaited(_handleTap(initial));

    WidgetsBinding.instance.addObserver(this);
    _ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    await FirebaseMessaging.instance.requestPermission();
  }

  /// Routes a tapped notification to where it's about: award pushes land on
  /// the Awards tab, completion/overdue pushes (which carry a `subjectId`)
  /// open that friend's page.
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
    _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: 'ic_stat_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
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
