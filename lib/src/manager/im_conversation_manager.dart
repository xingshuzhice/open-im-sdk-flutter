import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_openim_sdk/src/macos_openim_bridge.dart';

class ConversationManager {
  MethodChannel _channel;
  late OnConversationListener listener;

  ConversationManager(this._channel);

  /// Conversation Listener
  Future setConversationListener(OnConversationListener listener) {
    this.listener = listener;
    if (MacOSOpenIMBridge.instance.isSupported) {
      return MacOSOpenIMBridge.instance.call('setConversationListener', {});
    }
    return _channel.invokeMethod('setConversationListener', _buildParam({}));
  }

  /// Get All Conversations
  Future<List<ConversationInfo>> getAllConversationList({String? operationID}) {
    final params = {"operationID": Utils.checkOperationID(operationID)};
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getAllConversationList', params)
        : _channel.invokeMethod('getAllConversationList', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => ConversationInfo.fromJson(map)),
    );
  }

  /// Paginate Through Conversations
  /// [offset] Starting index
  /// [count] Number of items per page
  Future<List<ConversationInfo>> getConversationListSplit({
    int offset = 0,
    int count = 20,
    String? operationID,
  }) {
    final params = {
      'offset': offset,
      'count': count,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getConversationListSplit', params)
        : _channel.invokeMethod(
            'getConversationListSplit', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => ConversationInfo.fromJson(map)),
    );
  }

  /// Query a Conversation; if it doesn't exist, it will be created
  /// [sourceID] UserID for one-on-one conversation, GroupID for group conversation
  /// [sessionType] Reference [ConversationType]
  Future<ConversationInfo> getOneConversation({
    required String sourceID,
    required int sessionType,
    String? operationID,
  }) {
    final params = {
      "sourceID": sourceID,
      "sessionType": sessionType,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getOneConversation', params)
        : _channel.invokeMethod('getOneConversation', _buildParam(params));
    return future.then(
      (value) => Utils.toObj(value, (map) => ConversationInfo.fromJson(map)),
    );
  }

  /// Get Multiple Conversations by Conversation ID
  /// [conversationIDList] List of conversation IDs
  Future<List<ConversationInfo>> getMultipleConversation({
    required List<String> conversationIDList,
    String? operationID,
  }) {
    final params = {
      "conversationIDList": conversationIDList,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getMultipleConversation', params)
        : _channel.invokeMethod('getMultipleConversation', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => ConversationInfo.fromJson(map)),
    );
  }

  /// Set Conversation Draft
  /// [conversationID] Conversation ID
  /// [draftText] Draft text
  Future setConversationDraft({
    required String conversationID,
    required String draftText,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "draftText": draftText,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('setConversationDraft', params)
        : _channel.invokeMethod('setConversationDraft', _buildParam(params));
  }

  /// Pin a Conversation
  /// [conversationID] Conversation ID
  /// [isPinned] true: pin, false: unpin
  Future pinConversation({
    required String conversationID,
    required bool isPinned,
    String? operationID,
  }) {
    final req = ConversationReq(isPinned: isPinned);

    return setConversation(conversationID, req, operationID: operationID);
  }

  /// Hide a Conversation
  /// [conversationID] Conversation ID
  Future hideConversation({
    required String conversationID,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('hideConversation', params)
        : _channel.invokeMethod('hideConversation', _buildParam(params));
  }

  /// Hide All Conversations
  Future hideAllConversations({
    String? operationID,
  }) {
    final params = {"operationID": Utils.checkOperationID(operationID)};
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('hideAllConversations', params)
        : _channel.invokeMethod('hideAllConversations', _buildParam(params));
  }

  /// Query Conversation ID
  /// [sourceID] UserID for one-on-one, GroupID for group
  /// [sessionType] Reference [ConversationType]
  Future<dynamic> getConversationIDBySessionType({
    required String sourceID,
    required int sessionType,
    String? operationID,
  }) {
    final params = {
      'sourceID': sourceID,
      'sessionType': sessionType,
      'operationID': Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(
            'getConversationIDBySessionType',
            params,
          )
        : _channel.invokeMethod(
            'getConversationIDBySessionType',
            _buildParam(params),
          );
  }

  /// get total unread message count
  /// int.tryParse(count) ?? 0;
  Future<dynamic> getTotalUnreadMsgCount({
    String? operationID,
  }) {
    final params = {"operationID": Utils.checkOperationID(operationID)};
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getTotalUnreadMsgCount', params)
        : _channel.invokeMethod('getTotalUnreadMsgCount', _buildParam(params));
  }

  /// Message Do-Not-Disturb Setting
  /// [conversationID] Conversation ID
  /// [status] 0: normal; 1: not receiving messages; 2: receive online messages but not offline messages
  @Deprecated('use [setConversation] instead')
  Future<dynamic> setConversationRecvMessageOpt({
    required String conversationID,
    required int status,
    String? operationID,
  }) {
    final req = ConversationReq(recvMsgOpt: status);

    return setConversation(conversationID, req, operationID: operationID);
  }

  /// Message Do-Not-Disturb Setting
  /// [conversationID] Conversation ID
  /// [status] 0: normal; 1: not receiving messages; 2: receive online messages but not offline messages
  Future<List<dynamic>> getConversationRecvMessageOpt({
    required List<String> conversationIDList,
    String? operationID,
  }) {
    final params = {
      "conversationIDList": conversationIDList,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance
            .call('getConversationRecvMessageOpt', params)
        : _channel.invokeMethod(
            'getConversationRecvMessageOpt',
            _buildParam(params),
          );
    return future.then((value) => Utils.toListMap(value));
  }

  /// Self-Destruct Messages
  /// [conversationID] Conversation ID
  /// [isPrivate] true: enable, false: disable
  @Deprecated('use [setConversation] instead')
  Future<dynamic> setConversationPrivateChat({
    required String conversationID,
    required bool isPrivate,
    String? operationID,
  }) {
    final req = ConversationReq(isPrivateChat: isPrivate);

    return setConversation(conversationID, req, operationID: operationID);
  }

  /// Delete a Conversation Locally and from the Server
  /// [conversationID] Conversation ID
  Future<dynamic> deleteConversationAndDeleteAllMsg({
    required String conversationID,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(
            'deleteConversationAndDeleteAllMsg',
            params,
          )
        : _channel.invokeMethod(
            'deleteConversationAndDeleteAllMsg',
            _buildParam(params),
          );
  }

  /// Clear Messages in a Conversation
  /// [conversationID] Conversation ID
  Future<dynamic> clearConversationAndDeleteAllMsg({
    required String conversationID,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(
            'clearConversationAndDeleteAllMsg',
            params,
          )
        : _channel.invokeMethod(
            'clearConversationAndDeleteAllMsg',
            _buildParam(params),
          );
  }

  /// Delete All Local Conversations
  @Deprecated('use hideAllConversations instead')
  Future<dynamic> deleteAllConversationFromLocal({
    String? operationID,
  }) {
    return hideAllConversations(operationID: operationID);
  }

  /// Reset Mentioned (Group At) Flags [GroupAtType]
  /// [conversationID] Conversation ID
  @Deprecated('use [setConversation] instead')
  Future<dynamic> resetConversationGroupAtType({
    required String conversationID,
    String? operationID,
  }) {
    final req = ConversationReq(groupAtType: 0);

    return setConversation(conversationID, req, operationID: operationID);
  }

  /// Query @ All Flag
  Future<dynamic> getAtAllTag({
    String? operationID,
  }) {
    final params = {"operationID": Utils.checkOperationID(operationID)};
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getAtAllTag', params)
        : _channel.invokeMethod('getAtAllTag', _buildParam(params));
  }

  /// Get @ All Tag
  String get atAllTag => 'AtAllTag';

  /// Global Do-Not-Disturb
  /// [status] 0: normal; 1: not receiving messages; 2: receive online messages but not offline messages
  @Deprecated('use [OpenIM.iMManager.userManager.setSelfInfo()] instead')
  Future<dynamic> setGlobalRecvMessageOpt({
    required int status,
    String? operationID,
  }) {
    throw UnimplementedError('setGlobalRecvMessageOpt');
  }

  /// Set Self-Destruct Message Duration
  /// [conversationID] Conversation ID
  /// [burnDuration] Duration in seconds, default: 30s
  @Deprecated('use [setConversation] instead')
  Future<dynamic> setConversationBurnDuration({
    required String conversationID,
    int burnDuration = 30,
    String? operationID,
  }) {
    final req = ConversationReq(burnDuration: burnDuration);

    return setConversation(conversationID, req, operationID: operationID);
  }

  /// Mark Messages as Read
  /// [conversationID] Conversation ID
  Future markConversationMessageAsRead({
    required String conversationID,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(
            'markConversationMessageAsRead',
            params,
          )
        : _channel.invokeMethod(
            'markConversationMessageAsRead',
            _buildParam(params),
          );
  }

  /// search Conversations
  Future<List<ConversationInfo>> searchConversations(
    String name, {
    String? operationID,
  }) {
    final params = {
      'name': name,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('searchConversations', params)
        : _channel.invokeMethod('searchConversations', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => ConversationInfo.fromJson(map)),
    );
  }

  @Deprecated('use [setConversation] instead')
  Future setConversationEx(
    String conversationID, {
    String? ex,
    String? operationID,
  }) {
    final req = ConversationReq(ex: ex);

    return setConversation(conversationID, req, operationID: operationID);
  }

  /// Custom Sort for Conversation List
  List<ConversationInfo> simpleSort(List<ConversationInfo> list) => list
    ..sort((a, b) {
      if ((a.isPinned == true && b.isPinned == true) ||
          (a.isPinned != true && b.isPinned != true)) {
        int aCompare = a.draftTextTime! > a.latestMsgSendTime!
            ? a.draftTextTime!
            : a.latestMsgSendTime!;
        int bCompare = b.draftTextTime! > b.latestMsgSendTime!
            ? b.draftTextTime!
            : b.latestMsgSendTime!;
        if (aCompare > bCompare) {
          return -1;
        } else if (aCompare < bCompare) {
          return 1;
        } else {
          return 0;
        }
      } else if (a.isPinned == true && b.isPinned != true) {
        return -1;
      } else {
        return 1;
      }
    });

  Future changeInputStates({
    required String conversationID,
    required bool focus,
    String? operationID,
  }) {
    final params = {
      'focus': focus,
      'conversationID': conversationID,
      'operationID': Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('changeInputStates', params)
        : _channel.invokeMethod('changeInputStates', _buildParam(params));
  }

  Future<List<int>?> getInputStates(
    String conversationID,
    String userID, {
    String? operationID,
  }) {
    final params = {
      'conversationID': conversationID,
      'userID': userID,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getInputStates', params)
        : _channel.invokeMethod('getInputStates', _buildParam(params));
    return future.then((value) {
      print('getInputStates: $value');
      final result = Utils.toListMap(value);
      return List<int>.from(result);
    });
  }

  Future setConversation(
    String conversationID,
    ConversationReq req, {
    String? operationID,
  }) {
    final params = {
      'conversationID': conversationID,
      'req': req.toJson(),
      'operationID': Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('setConversation', params)
        : _channel.invokeMethod('setConversation', _buildParam(params));
  }

  static Map _buildParam(Map<String, dynamic> param) {
    param["ManagerName"] = "conversationManager";
    param = Utils.cleanMap(param);
    log('param: $param');

    return param;
  }
}
