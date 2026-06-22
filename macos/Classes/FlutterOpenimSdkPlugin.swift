import Cocoa
import FlutterMacOS

public class FlutterOpenimSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_openim_sdk",
      binaryMessenger: registrar.messenger
    )
    let instance = FlutterOpenimSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterError(
      code: "unsupported_platform",
      message: "当前平台暂未接入 OpenIM 原生 SDK",
      details: [
        "method": call.method,
        "platform": "macos"
      ]
    ))
  }
}
