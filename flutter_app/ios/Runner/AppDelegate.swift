import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Method channel for sharing files (PDF export)
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.mousetrap.app/share",
                                       binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { (call, result) in
      if call.method == "shareFile" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing path", details: nil))
          return
        }
        let url = URL(fileURLWithPath: path)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // iPad requires sourceView
        if let popover = activityVC.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(x: controller.view.bounds.midX,
                                      y: controller.view.bounds.midY, width: 0, height: 0)
          popover.permittedArrowDirections = []
        }
        controller.present(activityVC, animated: true, completion: nil)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
