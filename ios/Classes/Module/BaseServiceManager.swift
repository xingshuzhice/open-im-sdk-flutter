import Flutter
import UIKit

typealias ImHandler = (_ methodCall: FlutterMethodCall, _ result: @escaping FlutterResult) -> Void

class BaseServiceManager {
    let channel: FlutterMethodChannel
    private var methodHandlers: [String: ImHandler] = [:]
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.registerHandlers()
    }
    
    func handleMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method: String = call.method
        guard let handler = methodHandlers[method] else {
            print("Handle MethodName Error: \(typeName(self))'s method: [\(method)] not found")
            return
        }
        handler(call, result)
    }
    
    subscript(_ key: String) -> ImHandler? {
        get {
            methodHandlers[key]
        }
        set {
            methodHandlers[key] = newValue
        }
    }
    
    func registerHandlers() {
        
    }
    
    func callBack(_ result: @escaping FlutterResult, _ content: Any? = nil) {
        safeMainAsync {
            result(content)
        }
    }
}
