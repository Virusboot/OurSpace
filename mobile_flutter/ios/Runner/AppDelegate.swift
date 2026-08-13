import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var blurEffectView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let securityChannel = FlutterMethodChannel(name: "com.ourspace.app/security",
                                              binaryMessenger: controller.binaryMessenger)

    securityChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "enableFlagSecure" {
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureChanged), name: UIScreen.capturedDidChangeNotification, object: nil)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    showPrivacyOverlay()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    hidePrivacyOverlay()
  }

  @objc private func screenCaptureChanged() {
    if UIScreen.main.isCaptured {
      showPrivacyOverlay()
    } else {
      hidePrivacyOverlay()
    }
  }

  private func showPrivacyOverlay() {
    if blurEffectView == nil {
      let blurEffect = UIBlurEffect(style: .dark)
      blurEffectView = UIVisualEffectView(effect: blurEffect)
      blurEffectView?.frame = window?.bounds ?? UIScreen.main.bounds
      if let overlay = blurEffectView {
        window?.addSubview(overlay)
      }
    }
  }

  private func hidePrivacyOverlay() {
    blurEffectView?.removeFromSuperview()
    blurEffectView = null
  }
}
