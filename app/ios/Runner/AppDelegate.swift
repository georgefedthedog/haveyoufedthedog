import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // TEMPORARY: native breadcrumbs surfaced in the on-device debug-log card via
  // shared_preferences (the "flutter." prefix). Remove with the card.
  private let diagKey = "flutter.fcm_native_diag"
  // The cold-launch universal link, stashed for the Dart fallback below.
  private let coldLinkKey = "flutter.cold_deep_link"

  private func diag(_ message: String) {
    let prev = UserDefaults.standard.string(forKey: diagKey) ?? ""
    UserDefaults.standard.set(
      prev.isEmpty ? message : prev + " | " + message,
      forKey: diagKey
    )
  }

  private func captureColdLink(_ url: URL, source: String) {
    diag("cold link via \(source): \(url.absoluteString)")
    UserDefaults.standard.set(url.absoluteString, forKey: coldLinkKey)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UserDefaults.standard.removeObject(forKey: diagKey)
    UserDefaults.standard.removeObject(forKey: coldLinkKey)

    // Configure Firebase natively before the engine so Messaging is ready when
    // the APNs callback fires (the implicit-engine embedding doesn't auto-wire
    // this). Dart's Firebase.initializeApp() then reuses this default app.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      diag("FirebaseApp.configure() called")
    } else {
      diag("FirebaseApp already configured")
    }

    // The implicit-engine embedding doesn't auto-register for remote
    // notifications, so the APNs device-token callback never fires. Do it here.
    application.registerForRemoteNotifications()
    diag("registerForRemoteNotifications() called")

    // A cold launch from a universal link can deliver the activity here, in
    // launchOptions. Capture it for the Dart fallback - app_links misses the
    // cold-launch link under the new iOS embedding.
    if let dict = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any] {
      for value in dict.values {
        if let activity = value as? NSUserActivity,
           activity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = activity.webpageURL {
          captureColdLink(url, source: "launchOptions")
        }
      }
    } else {
      diag("no userActivity in launchOptions")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Universal links (warm and, at launch, cold) come through here. Stash the
  // URL so Dart can recover the cold-launch one when app_links' getInitialLink
  // returns null under the implicit-engine embedding.
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      captureColdLink(url, source: "continueUserActivity")
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    diag("didRegister: apnsToken set (\(deviceToken.count) bytes)")
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    diag("didFailToRegister: \(error.localizedDescription)")
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
