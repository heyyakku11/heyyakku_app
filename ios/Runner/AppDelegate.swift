import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerInstagramStoryChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  // MARK: - Instagram Story sharing

  private func registerInstagramStoryChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.example.yakku/instagram_story",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "shareToStory" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let imagePath = args["imagePath"] as? String,
        let appId = args["appId"] as? String, !appId.isEmpty
      else {
        result(FlutterError(code: "bad_args", message: "imagePath and appId are required", details: nil))
        return
      }
      let linkText = args["linkText"] as? String
      AppDelegate.shareToInstagramStory(
        imagePath: imagePath, appId: appId, linkText: linkText, result: result)
    }
  }

  /// Puts the PNG on the pasteboard in Instagram's Story format, then opens
  /// `instagram-stories://share`. The link rides along as plain text in the same
  /// pasteboard item (setting the pasteboard would otherwise wipe the copied
  /// link); Instagram reads the image type, the user can still paste the text.
  private static func shareToInstagramStory(
    imagePath: String,
    appId: String,
    linkText: String?,
    result: @escaping FlutterResult
  ) {
    var components = URLComponents(string: "instagram-stories://share")
    components?.queryItems = [URLQueryItem(name: "source_application", value: appId)]
    guard let url = components?.url else {
      result(FlutterError(code: "bad_url", message: "Could not build Instagram URL", details: nil))
      return
    }
    guard UIApplication.shared.canOpenURL(url) else {
      result("notInstalled")
      return
    }
    guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
      result(FlutterError(code: "missing_file", message: "Story image not found", details: nil))
      return
    }
    var item: [String: Any] = ["com.instagram.sharedSticker.backgroundImage": imageData]
    if let linkText, !linkText.isEmpty {
      item["public.utf8-plain-text"] = linkText
    }
    UIPasteboard.general.setItems([item], options: [:])
    UIApplication.shared.open(url, options: [:]) { opened in
      if opened {
        result("opened")
      } else {
        result(FlutterError(code: "open_failed", message: "Could not open Instagram", details: nil))
      }
    }
  }
}
