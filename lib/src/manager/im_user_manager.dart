import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_openim_sdk/src/macos_openim_bridge.dart';

class UserManager {
  MethodChannel _channel;
  late OnUserListener listener;

  UserManager(this._channel);

  /// User profile change listener
  Future setUserListener(OnUserListener listener) {
    this.listener = listener;
    if (MacOSOpenIMBridge.instance.isSupported) {
      return MacOSOpenIMBridge.instance.call('setUserListener', {});
    }
    return _channel.invokeMethod('setUserListener', _buildParam({}));
  }

  /// Get user information
  /// [userIDList] List of user IDs
  Future<List<PublicUserInfo>> getUsersInfo({
    required List<String> userIDList,
    String? operationID,
  }) {
    final params = {
      'userIDList': userIDList,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getUsersInfo', params)
        : _channel.invokeMethod('getUsersInfo', _buildParam(params));
    return future.then(
        (value) => Utils.toList(value, (v) => PublicUserInfo.fromJson(v)));
  }

  /// Get information of the currently logged-in user
  Future<UserInfo> getSelfUserInfo({
    String? operationID,
  }) {
    final params = {'operationID': Utils.checkOperationID(operationID)};
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getSelfUserInfo', params)
        : _channel.invokeMethod('getSelfUserInfo', _buildParam(params));
    return future
        .then((value) => Utils.toObj(value, (map) => UserInfo.fromJson(map)));
  }

  /// Modify the profile of the currently logged-in user
  /// [nickname] Nickname
  /// [faceURL] Profile picture
  /// [appManagerLevel]
  /// [ex] Additional fields
  Future<String?> setSelfInfo({
    String? nickname,
    String? faceURL,
    int? globalRecvMsgOpt,
    String? ex,
    String? operationID,
  }) {
    final params = {
      'nickname': nickname,
      'faceURL': faceURL,
      'globalRecvMsgOpt': globalRecvMsgOpt,
      'ex': ex,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('setSelfInfo', params)
        : _channel.invokeMethod('setSelfInfo', _buildParam(params));
    return future.then((value) => value?.toString());
  }

  Future<List<UserStatusInfo>> subscribeUsersStatus(
    List<String> userIDs, {
    String? operationID,
  }) {
    final params = {
      'userIDs': userIDs,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('subscribeUsersStatus', params)
        : _channel.invokeMethod('subscribeUsersStatus', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => UserStatusInfo.fromJson(map)),
    );
  }

  Future unsubscribeUsersStatus(
    List<String> userIDs, {
    String? operationID,
  }) {
    final params = {
      'userIDs': userIDs,
      'operationID': Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('unsubscribeUsersStatus', params)
        : _channel.invokeMethod('unsubscribeUsersStatus', _buildParam(params));
  }

  Future<List<UserStatusInfo>> getSubscribeUsersStatus({
    String? operationID,
  }) {
    final params = {
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getSubscribeUsersStatus', params)
        : _channel.invokeMethod(
            'getSubscribeUsersStatus',
            _buildParam(params),
          );
    return future.then(
      (value) => Utils.toList(value, (map) => UserStatusInfo.fromJson(map)),
    );
  }

  Future<List<UserStatusInfo>> getUserStatus(
    List<String> userIDs, {
    String? operationID,
  }) {
    final params = {
      'userIDs': userIDs,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getUserStatus', params)
        : _channel.invokeMethod('getUserStatus', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => UserStatusInfo.fromJson(map)),
    );
  }

  @Deprecated('Use [getUsersInfo] instead')
  Future<List<PublicUserInfo>> getUsersInfoWithCache(
    List<String> userIDs, {
    String? operationID,
  }) {
    return getUsersInfo(userIDList: userIDs, operationID: operationID);
  }

  /// Global Do Not Disturb
  /// [status] 0: Normal; 1: Do not accept messages; 2: Accept online messages but not offline messages;
  @Deprecated('use [setSelfInfo] instead')
  Future<dynamic> setGlobalRecvMessageOpt({
    required int status,
    String? operationID,
  }) {
    return setSelfInfo(globalRecvMsgOpt: status);
  }

  static Map _buildParam(Map<String, dynamic> param) {
    param["ManagerName"] = "userManager";
    param = Utils.cleanMap(param);

    return param;
  }
}
