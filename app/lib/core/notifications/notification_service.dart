import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../completions/recent_completions_controller.dart';
import '../completions/today_completions_controller.dart';

part 'notification_service.g.dart';

const _channelId = 'chore_completions';
const _channelName = 'Chore completions';
const _channelDescription = 'When someone in your household logs a chore.';

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

    WidgetsBinding.instance.addObserver(this);
    _ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    await FirebaseMessaging.instance.requestPermission();
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
