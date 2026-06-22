import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_openim_sdk/src/macos_openim_bridge.dart';

class MessageManager {
  MethodChannel _channel;

  OnMsgSendProgressListener? msgSendProgressListener;
  late OnAdvancedMsgListener msgListener;
  OnCustomBusinessListener? customBusinessListener;

  MessageManager(this._channel);

  /// Message listener
  Future setAdvancedMsgListener(OnAdvancedMsgListener listener) {
    this.msgListener = listener;
    // advancedMsgListeners.add(listener);
    if (MacOSOpenIMBridge.instance.isSupported) {
      return MacOSOpenIMBridge.instance.call('setAdvancedMsgListener', {
        'id': listener.id,
      });
    }
    return _channel.invokeMethod(
        'setAdvancedMsgListener',
        _buildParam({
          'id': listener.id,
        }));
  }

  /// Message send progress listener
  void setMsgSendProgressListener(OnMsgSendProgressListener listener) {
    msgSendProgressListener = listener;
  }

  /// Send a message
  /// [message] Message content
  /// [userID] User ID of the recipient
  /// [groupID] Group ID of the recipient
  /// [offlinePushInfo] Offline message display content
  Future<Message> sendMessage({
    required Message message,
    required OfflinePushInfo offlinePushInfo,
    String? userID,
    String? groupID,
    bool isOnlineOnly = false,
    String? operationID,
  }) {
    final params = {
      'message': message.toJson(),
      'offlinePushInfo': offlinePushInfo.toJson(),
      'userID': userID ?? '',
      'groupID': groupID ?? '',
      'isOnlineOnly': isOnlineOnly,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('sendMessage', params)
        : _channel.invokeMethod('sendMessage', _buildParam(params));
    return future
        .then((value) => Utils.toObj(value, (map) => Message.fromJson(map)));
  }

  /// Delete a message from local storage
  /// [message] Message to be deleted
  Future deleteMessageFromLocalStorage({
    required String conversationID,
    required String clientMsgID,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "clientMsgID": clientMsgID,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance
            .call('deleteMessageFromLocalStorage', params)
        : _channel.invokeMethod(
            'deleteMessageFromLocalStorage',
            _buildParam(params),
          );
  }

  /// core-sdk: DeleteMessage
  /// Delete a specified message from local and server
  /// [message] Message to be deleted
  Future<dynamic> deleteMessageFromLocalAndSvr({
    required String conversationID,
    required String clientMsgID,
    String? operationID,
  }) {
    final params = {
      "conversationID": conversationID,
      "clientMsgID": clientMsgID,
      "operationID": Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance
            .call('deleteMessageFromLocalAndSvr', params)
        : _channel.invokeMethod(
            'deleteMessageFromLocalAndSvr',
            _buildParam(params),
          );
  }

  /// Delete all local chat records
  Future<dynamic> deleteAllMsgFromLocal({
    String? operationID,
  }) {
    return _invoke('deleteAllMsgFromLocal', {
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Delete all chat records from local and server
  Future<dynamic> deleteAllMsgFromLocalAndSvr({
    String? operationID,
  }) {
    return _invoke('deleteAllMsgFromLocalAndSvr', {
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Insert a single chat message into local storage
  /// [receiverID] Receiver's ID
  /// [senderID] Sender's ID
  /// [message] Message content
  Future<Message> insertSingleMessageToLocalStorage({
    String? receiverID,
    String? senderID,
    Message? message,
    String? operationID,
  }) {
    return _invokeMessage('insertSingleMessageToLocalStorage', {
      "message": message?.toJson(),
      "receiverID": receiverID,
      "senderID": senderID,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Insert a group chat message into local storage
  /// [groupID] Group ID
  /// [senderID] Sender's ID
  /// [message] Message content
  Future<Message> insertGroupMessageToLocalStorage({
    String? groupID,
    String? senderID,
    Message? message,
    String? operationID,
  }) {
    return _invokeMessage('insertGroupMessageToLocalStorage', {
      "message": message?.toJson(),
      "groupID": groupID,
      "senderID": senderID,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Typing status update
  /// [msgTip] Custom content
  @Deprecated(
      'Use [OpenIM.iMManager.conversationManager.changeInputStates(conversationID:focus:)] instead')
  Future typingStatusUpdate({
    required String userID,
    String? msgTip,
    String? operationID,
  }) {
    return _invoke('typingStatusUpdate', {
      'userID': userID,
      'msgTip': msgTip,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Create a text message
  Future<Message> createTextMessage({
    required String text,
    String? operationID,
  }) {
    final params = {
      'text': text,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('createTextMessage', params)
        : _channel.invokeMethod('createTextMessage', _buildParam(params));
    return future
        .then((value) => Utils.toObj(value, (map) => Message.fromJson(map)));
  }

  /// Create an @ message
  /// [text] Input content
  /// [atUserIDList] Collection of userIDs being mentioned
  /// [atUserInfoList] Mapping of userID to nickname, used for displaying nicknames instead of IDs in the user interface
  /// [quoteMessage] Quoted message (the message being replied to)
  Future<Message> createTextAtMessage({
    required String text,
    required List<String> atUserIDList,
    List<AtUserInfo> atUserInfoList = const [],
    Message? quoteMessage,
    String? operationID,
  }) {
    return _invokeMessage('createTextAtMessage', {
      'text': text,
      'atUserIDList': atUserIDList,
      'atUserInfoList': atUserInfoList.map((e) => e.toJson()).toList(),
      'quoteMessage': quoteMessage?.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create an image message
  /// [imagePath] Path
  Future<Message> createImageMessage({
    required String imagePath,
    String? operationID,
  }) {
    return _invokeMessage('createImageMessage', {
      'imagePath': imagePath,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create an image message from a full path
  /// [imagePath] Path
  Future<Message> createImageMessageFromFullPath({
    required String imagePath,
    String? operationID,
  }) {
    return _invokeMessage('createImageMessageFromFullPath', {
      'imagePath': imagePath,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a sound message
  /// [soundPath] Path
  /// [duration] Duration in seconds
  Future<Message> createSoundMessage({
    required String soundPath,
    required int duration,
    String? operationID,
  }) {
    return _invokeMessage('createSoundMessage', {
      'soundPath': soundPath,
      "duration": duration,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a sound message from a full path
  /// [soundPath] Path
  /// [duration] Duration in seconds
  Future<Message> createSoundMessageFromFullPath({
    required String soundPath,
    required int duration,
    String? operationID,
  }) {
    return _invokeMessage('createSoundMessageFromFullPath', {
      'soundPath': soundPath,
      "duration": duration,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a video message
  /// [videoPath] Path
  /// [videoType] Video MIME type
  /// [duration] Duration in seconds
  /// [snapshotPath] Default snapshot image path
  Future<Message> createVideoMessage({
    required String videoPath,
    required String videoType,
    required int duration,
    required String snapshotPath,
    String? operationID,
  }) {
    return _invokeMessage('createVideoMessage', {
      'videoPath': videoPath,
      'videoType': videoType,
      'duration': duration,
      'snapshotPath': snapshotPath,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a video message from a full path
  /// [videoPath] Path
  /// [videoType] Video MIME type
  /// [duration] Duration in seconds
  /// [snapshotPath] Default snapshot image path
  Future<Message> createVideoMessageFromFullPath({
    required String videoPath,
    required String videoType,
    required int duration,
    required String snapshotPath,
    String? operationID,
  }) {
    return _invokeMessage('createVideoMessageFromFullPath', {
      'videoPath': videoPath,
      'videoType': videoType,
      'duration': duration,
      'snapshotPath': snapshotPath,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a file message
  /// [filePath] Path
  /// [fileName] File name
  Future<Message> createFileMessage({
    required String filePath,
    required String fileName,
    String? operationID,
  }) {
    return _invokeMessage('createFileMessage', {
      'filePath': filePath,
      'fileName': fileName,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a file message from a full path
  /// [filePath] Path
  /// [fileName] File name
  Future<Message> createFileMessageFromFullPath({
    required String filePath,
    required String fileName,
    String? operationID,
  }) {
    return _invokeMessage('createFileMessageFromFullPath', {
      'filePath': filePath,
      'fileName': fileName,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a merged message
  /// [messageList] Selected messages
  /// [title] Summary title
  /// [summaryList] Summary content
  Future<Message> createMergerMessage({
    required List<Message> messageList,
    required String title,
    required List<String> summaryList,
    String? operationID,
  }) {
    return _invokeMessage('createMergerMessage', {
      'messageList': messageList.map((e) => e.toJson()).toList(),
      'title': title,
      'summaryList': summaryList,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a forwarded message
  /// [message] Message to be forwarded
  Future<Message> createForwardMessage({
    required Message message,
    String? operationID,
  }) {
    final params = {
      'message': message.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('createForwardMessage', params)
        : _channel.invokeMethod('createForwardMessage', _buildParam(params));
    return future
        .then((value) => Utils.toObj(value, (map) => Message.fromJson(map)));
  }

  /// Create a location message
  /// [latitude] Latitude
  /// [longitude] Longitude
  /// [description] Custom description
  Future<Message> createLocationMessage({
    required double latitude,
    required double longitude,
    required String description,
    String? operationID,
  }) {
    return _invokeMessage('createLocationMessage', {
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a custom message
  /// [data] Custom data
  /// [extension] Custom extension content
  /// [description] Custom description content
  Future<Message> createCustomMessage({
    required String data,
    required String extension,
    required String description,
    String? operationID,
  }) {
    return _invokeMessage('createCustomMessage', {
      'data': data,
      'extension': extension,
      'description': description,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a quoted message
  /// [text] Reply content
  /// [quoteMsg] Message being replied to
  Future<Message> createQuoteMessage({
    required String text,
    required Message quoteMsg,
    String? operationID,
  }) {
    final params = {
      'quoteText': text,
      'quoteMessage': quoteMsg.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('createQuoteMessage', params)
        : _channel.invokeMethod('createQuoteMessage', _buildParam(params));
    return future
        .then((value) => Utils.toObj(value, (map) => Message.fromJson(map)));
  }

  /// Create a card message
  /// [data] Custom data
  Future<Message> createCardMessage({
    required String userID,
    required String nickname,
    String? faceURL,
    String? ex,
    String? operationID,
  }) {
    return _invokeMessage('createCardMessage', {
      'cardMessage': {
        'userID': userID,
        'nickname': nickname,
        'faceURL': faceURL,
        'ex': ex,
      },
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a custom emoji message
  /// [index] Positional emoji, matched based on index
  /// [data] URL emoji, displayed directly using the URL
  Future<Message> createFaceMessage({
    int index = -1,
    String? data,
    String? operationID,
  }) {
    return _invokeMessage('createFaceMessage', {
      'index': index,
      'data': data,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Search messages
  /// [conversationID] Query based on conversation, pass null for global search
  /// [keywordList] Search keyword list, currently supports searching with a single keyword
  /// [keywordListMatchType] Keyword matching mode, 1 means AND, 2 means OR (currently unused)
  /// [senderUserIDList] List of UIDs for messages sent (currently unused)
  /// [messageTypeList] Message type list
  /// [searchTimePosition] Start time point for searching. Defaults to 0, meaning searching from now. UTC timestamp, in seconds
  /// [searchTimePeriod] Time range in the past from the start time point, in seconds. Defaults to 0, meaning no time range limitation. Pass 24x60x60 to represent the past day
  /// [pageIndex] Current page number
  /// [count] Number of messages per page
  Future<SearchResult> searchLocalMessages({
    String? conversationID,
    List<String> keywordList = const [],
    int keywordListMatchType = 0,
    List<String> senderUserIDList = const [],
    List<int> messageTypeList = const [],
    int searchTimePosition = 0,
    int searchTimePeriod = 0,
    int pageIndex = 1,
    int count = 40,
    String? operationID,
  }) {
    final params = {
      'filter': {
        'conversationID': conversationID,
        'keywordList': keywordList,
        'keywordListMatchType': keywordListMatchType,
        'senderUserIDList': senderUserIDList,
        'messageTypeList': messageTypeList,
        'searchTimePosition': searchTimePosition,
        'searchTimePeriod': searchTimePeriod,
        'pageIndex': pageIndex,
        'count': count,
      },
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('searchLocalMessages', params)
        : _channel.invokeMethod('searchLocalMessages', _buildParam(params));
    return future.then(
        (value) => Utils.toObj(value, (map) => SearchResult.fromJson(map)));
  }

  /// Revoke a message
  /// [message] The message to be revoked
  Future revokeMessage({
    required String conversationID,
    required String clientMsgID,
    String? operationID,
  }) {
    return _invoke('revokeMessage', {
      'conversationID': conversationID,
      'clientMsgID': clientMsgID,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Mark messages as read
  /// [conversationID] Conversation ID
  /// [messageIDList] List of clientMsgIDs of messages to be marked as read
  @Deprecated('Use markConversationMessageAsRead instead')
  Future markMessagesAsReadByMsgID({
    required String conversationID,
    required List<String> messageIDList,
    String? operationID,
  }) {
    return _invoke('markMessagesAsReadByMsgID', {
      "conversationID": conversationID,
      "messageIDList": messageIDList,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Get chat history (messages prior to startMsg)
  /// [conversationID] Conversation ID, can be used for querying notifications
  /// [startMsg] Query [count] messages starting from this message. The message at index == length - 1 is the latest message, so to get the next page of history, use startMsg = list.first
  /// [count] Total number of messages to retrieve in one request
  /// [lastMinSeq] Not required for the first page of messages, but necessary for getting the second page of history. Same as [startMsg]
  Future<AdvancedMessage> getAdvancedHistoryMessageList({
    String? conversationID,
    Message? startMsg,
    GetHistoryViewType viewType = GetHistoryViewType.history,
    int? count,
    String? operationID,
  }) {
    final params = {
      'conversationID': conversationID ?? '',
      'startClientMsgID': startMsg?.clientMsgID ?? '',
      'count': count ?? 40,
      'viewType': viewType.rawValue,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance
            .call('getAdvancedHistoryMessageList', params)
        : _channel.invokeMethod(
            'getAdvancedHistoryMessageList',
            _buildParam(params),
          );
    return future.then(
        (value) => Utils.toObj(value, (map) => AdvancedMessage.fromJson(map)));
  }

  /// Get chat history (newly received chat history after startMsg). Used for locating a specific message in global search and then fetching messages received after that message.
  /// [conversationID] Conversation ID, can be used for querying notifications
  /// [startMsg] Query [count] messages starting from this message. The message at index == length - 1 is the latest message, so to get the next page of history, use startMsg = list.last
  /// [count] Total number of messages to retrieve in one request
  Future<AdvancedMessage> getAdvancedHistoryMessageListReverse({
    String? conversationID,
    Message? startMsg,
    GetHistoryViewType viewType = GetHistoryViewType.history,
    int? count,
    String? operationID,
  }) {
    final params = {
      'conversationID': conversationID ?? '',
      'startClientMsgID': startMsg?.clientMsgID ?? '',
      'count': count ?? 40,
      'viewType': viewType.rawValue,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(
            'getAdvancedHistoryMessageListReverse',
            params,
          )
        : _channel.invokeMethod(
            'getAdvancedHistoryMessageListReverse',
            _buildParam(params),
          );
    return future.then(
        (value) => Utils.toObj(value, (map) => AdvancedMessage.fromJson(map)));
  }

  /// Find message details
  /// [conversationID] Conversation ID
  /// [clientMsgIDList] List of message IDs
  Future<SearchResult> findMessageList({
    required List<SearchParams> searchParams,
    String? operationID,
  }) {
    final future = _invoke('findMessageList', {
      'searchParams': searchParams.map((e) => e.toJson()).toList(),
      'operationID': Utils.checkOperationID(operationID),
    });
    return future.then(
      (value) => Utils.toObj(value, (map) => SearchResult.fromJson(map)),
    );
  }

  /// Rich text message
  /// [text] Input content
  /// [list] Details of the rich text message
  Future<Message> createAdvancedTextMessage({
    required String text,
    List<RichMessageInfo> list = const [],
    String? operationID,
  }) {
    return _invokeMessage('createAdvancedTextMessage', {
      'text': text,
      'richMessageInfoList': list.map((e) => e.toJson()).toList(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Rich text message with quote
  /// [text] Content for the reply
  /// [quoteMsg] The message being replied to
  /// [list] Details of the rich text message
  Future<Message> createAdvancedQuoteMessage({
    required String text,
    required Message quoteMsg,
    List<RichMessageInfo> list = const [],
    String? operationID,
  }) {
    return _invokeMessage('createAdvancedQuoteMessage', {
      'quoteText': text,
      'quoteMessage': quoteMsg.toJson(),
      'richMessageInfoList': list.map((e) => e.toJson()).toList(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Send a message
  /// [message] Message body [createImageMessageByURL],[createSoundMessageByURL],[createVideoMessageByURL],[createFileMessageByURL]
  /// [userID] User ID to receive the message
  /// [groupID] Group ID to receive the message
  /// [offlinePushInfo] Offline message display content
  Future<Message> sendMessageNotOss({
    required Message message,
    required OfflinePushInfo offlinePushInfo,
    String? userID,
    String? groupID,
    bool isOnlineOnly = false,
    String? operationID,
  }) {
    return _invokeMessage('sendMessageNotOss', {
      'message': message.toJson(),
      'offlinePushInfo': offlinePushInfo.toJson(),
      'userID': userID ?? '',
      'groupID': groupID ?? '',
      'isOnlineOnly': isOnlineOnly,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Create an image message by URL
  Future<Message> createImageMessageByURL({
    required PictureInfo sourcePicture,
    required PictureInfo bigPicture,
    required PictureInfo snapshotPicture,
    String? sourcePath,
    String? operationID,
  }) {
    return _invokeMessage('createImageMessageByURL', {
      'sourcePath': sourcePath,
      'sourcePicture': sourcePicture.toJson(),
      'bigPicture': bigPicture.toJson(),
      'snapshotPicture': snapshotPicture.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a sound message
  Future<Message> createSoundMessageByURL({
    required SoundElem soundElem,
    String? operationID,
  }) {
    return _invokeMessage('createSoundMessageByURL', {
      'soundElem': soundElem.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a video message
  Future<Message> createVideoMessageByURL({
    required VideoElem videoElem,
    String? operationID,
  }) {
    return _invokeMessage('createVideoMessageByURL', {
      'videoElem': videoElem.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Create a file message
  Future<Message> createFileMessageByURL({
    required FileElem fileElem,
    String? operationID,
  }) {
    return _invokeMessage('createFileMessageByURL', {
      'fileElem': fileElem.toJson(),
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  ///
  Future setCustomBusinessListener(OnCustomBusinessListener listener) {
    this.customBusinessListener = listener;
    if (MacOSOpenIMBridge.instance.isSupported) {
      return MacOSOpenIMBridge.instance.call('setCustomBusinessListener', {});
    }
    return _channel.invokeMethod('setCustomBusinessListener', _buildParam({}));
  }

  Future setMessageLocalEx({
    required String conversationID,
    required String clientMsgID,
    required String localEx,
    String? operationID,
  }) {
    return _invoke('setMessageLocalEx', {
      "conversationID": conversationID,
      "clientMsgID": clientMsgID,
      "localEx": localEx,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  Future setAppBadge(
    int count, {
    String? operationID,
  }) {
    return _invoke('setAppBadge', {
      'count': count,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  Future<dynamic> _invoke(String method, Map<String, dynamic> params) {
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(method, params)
        : _channel.invokeMethod(method, _buildParam(params));
  }

  Future<Message> _invokeMessage(String method, Map<String, dynamic> params) {
    return _invoke(method, params).then(
      (value) => Utils.toObj(value, (map) => Message.fromJson(map)),
    );
  }

  static Map _buildParam(Map<String, dynamic> param) {
    param["ManagerName"] = "messageManager";
    param = Utils.cleanMap(param);

    return param;
  }
}
