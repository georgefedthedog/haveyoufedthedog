import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // The implicit-engine embedding registers plugins against the engine's
  // plugin registry, which is NOT wired into the app-level UIApplicationDelegate
  // callbacks. As a result the APNs device token iOS delivers here never
  // reaches Firebase Messaging, so getToken() throws apns-token-not-set and no
  // FCM token is ever minted. Hand the token to Firebase explicitly (the
  // canonical FlutterFire fix), then forward to super so any plugin lifecycle
  // delegates that DO get wired up keep working.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
