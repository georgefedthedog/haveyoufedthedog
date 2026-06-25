import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // TEMPORARY: native-side breadcrumbs for the iOS push-token chain, stashed in
  // NSUserDefaults under the "flutter." prefix so the Dart diagnostics card can
  // read them back via shared_preferences. Remove with the card once push works.
  private let diagKey = "flutter.fcm_native_diag"

  private func diag(_ message: String) {
    let prev = UserDefaults.standard.string(forKey: diagKey) ?? ""
    UserDefaults.standard.set(
      prev.isEmpty ? message : prev + " | " + message,
      forKey: diagKey
    )
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UserDefaults.standard.removeObject(forKey: diagKey)

    // Configure Firebase natively BEFORE the Flutter engine (and so before any
    // APNs callback) so Messaging is ready to hold the token. The Dart-side
    // Firebase.initializeApp() then reuses this default app. Without this, the
    // implicit-engine embedding leaves Firebase unconfigured when the token
    // would arrive.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      diag("FirebaseApp.configure() called")
    } else {
      diag("FirebaseApp already configured")
    }

    // The implicit-engine embedding does not auto-register for remote
    // notifications the way the classic plugin wiring did, so the APNs
    // device-token callback never fires. Request it explicitly.
    application.registerForRemoteNotifications()
    diag("registerForRemoteNotifications() called")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
