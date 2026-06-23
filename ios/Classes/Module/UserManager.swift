import Foundation
import OpenIMCore

class UserManager: BaseServiceManager {

  override func registerHandlers() {
        super.registerHandlers()
        self["setUserListener"] = setUserListener
        self["getUsersInfo"] = getUsersInfo
        self["setSelfInfo"] = setSelfInfo
        self["getSelfUserInfo"] = getSelfUserInfo
        self["subscribeUsersStatus"] = subscribeUsersStatus
        self["unsubscribeUsersStatus"] = unsubscribeUsersStatus
        self["getSubscribeUsersStatus"] = getSubscribeUsersStatus
        self["getUserStatus"] = getUserStatus
    }

    func setUserListener(methodCall: FlutterMethodCall, result: @escaping FlutterResult){
        Open_im_sdkSetUserListener(UserListener(channel: channel))
        callBack(result)
    }

    func getUsersInfo(methodCall: FlutterMethodCall, result: @escaping FlutterResult) {
        Open_im_sdkGetUsersInfo(BaseCallback(result: result), methodCall[string: "operationID"], methodCall[jsonString: "userIDList"])
    }
    
    func setSelfInfo(methodCall: FlutterMethodCall, result: @escaping FlutterResult) {
        Open_im_sdkSetSelfInfo(BaseCallback(result: result), methodCall[string: "operationID"], methodCall.toJsonString())
    }
    
    func getSelfUserInfo(methodCall: FlutterMethodCall, result: @escaping FlutterResult) {
        Open_im_sdkGetSelfUserInfo(BaseCallback(result: result), methodCall[string: "operationID"])
    }

    func subscribeUsersStatus(methodCall: FlutterMethodCall, result: @escaping FlutterResult){
        Open_im_sdkSubscribeUsersStatus(BaseCallback(result: result), methodCall[string: "operationID"], methodCall[jsonString: "userIDs"])
    }

    func unsubscribeUsersStatus(methodCall: FlutterMethodCall, result: @escaping FlutterResult){
        Open_im_sdkUnsubscribeUsersStatus(BaseCallback(result: result), methodCall[string: "operationID"], methodCall[jsonString: "userIDs"])
    }

    func getSubscribeUsersStatus(methodCall: FlutterMethodCall, result: @escaping FlutterResult){
        Open_im_sdkGetSubscribeUsersStatus(BaseCallback(result: result), methodCall[string: "operationID"])
    }

    func getUserStatus(methodCall: FlutterMethodCall, result: @escaping FlutterResult){
        Open_im_sdkGetUserStatus(BaseCallback(result: result), methodCall[string: "operationID"], methodCall[jsonString: "userIDs"])
    }
}

class UserListener: NSObject, Open_im_sdk_callbackOnUserListenerProtocol {
    func onUserCommandAdd(_ userCommand: String?) {
        CommonUtil.emitEvent(channel: self.channel, method: "userListener", type: "onUserCommandAdd", errCode: nil, errMsg: nil, data: userCommand)
    }
    
    func onUserCommandDelete(_ userCommand: String?) {
        CommonUtil.emitEvent(channel: self.channel, method: "userListener", type: "onUserCommandDelete", errCode: nil, errMsg: nil, data: userCommand)
    }
    
    func onUserCommandUpdate(_ userCommand: String?) {
        CommonUtil.emitEvent(channel: self.channel, method: "userListener", type: "onUserCommandUpdate", errCode: nil, errMsg: nil, data: userCommand)
    }
    
    
    private let channel:FlutterMethodChannel

    init(channel:FlutterMethodChannel) {
        self.channel = channel
    }
    
    func onSelfInfoUpdated(_ userInfo: String?) {
        CommonUtil.emitEvent(channel: self.channel, method: "userListener", type: "onSelfInfoUpdated", errCode: nil, errMsg: nil, data: userInfo)
    }
    
    func onUserStatusChanged(_ statusInfo: String?) {
        CommonUtil.emitEvent(channel: self.channel, method: "userListener", type: "onUserStatusChanged", errCode: nil, errMsg: nil, data: statusInfo)
    }

}
