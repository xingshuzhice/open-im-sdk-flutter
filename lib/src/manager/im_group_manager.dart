import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_openim_sdk/src/macos_openim_bridge.dart';

class GroupManager {
  MethodChannel _channel;
  late OnGroupListener listener;

  GroupManager(this._channel);

  /// Group relationship listener
  Future setGroupListener(OnGroupListener listener) {
    this.listener = listener;
    if (MacOSOpenIMBridge.instance.isSupported) {
      return MacOSOpenIMBridge.instance.call('setGroupListener', {});
    }
    return _channel.invokeMethod('setGroupListener', _buildParam({}));
  }

  /// Invite users to a group, allowing them to join without approval.
  /// [groupID] Group ID
  /// [userIDList] List of user IDs
  Future inviteUserToGroup({
    required String groupID,
    required List<String> userIDList,
    String? reason,
    String? operationID,
  }) {
    return _invoke('inviteUserToGroup', {
      'groupID': groupID,
      'userIDList': userIDList,
      'reason': reason,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Remove group members
  /// [groupID] Group ID
  /// [userIDList] List of user IDs
  /// [reason] Reason for removal
  Future kickGroupMember({
    required String groupID,
    required List<String> userIDList,
    String? reason,
    String? operationID,
  }) {
    return _invoke('kickGroupMember', {
      'groupID': groupID,
      'userIDList': userIDList,
      'reason': reason,
      "operationID": Utils.checkOperationID(operationID),
    });
  }

  /// Query group member information
  /// [groupID] Group ID
  /// [userIDList] List of user IDs
  Future<List<GroupMembersInfo>> getGroupMembersInfo({
    required String groupID,
    required List<String> userIDList,
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'userIDList': userIDList,
      "operationID": Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getGroupMembersInfo', params)
        : _channel.invokeMethod('getGroupMembersInfo', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupMembersInfo.fromJson(map)),
    );
  }

  /// Paginate and retrieve the group member list
  /// [groupID] Group ID
  /// [filter] Member filter (0: All, 1: Group owner, 2: Administrator, 3: Regular member, 4: Admin + Regular member, 5: Group owner + Admin)
  /// [offset] Starting index
  /// [count] Total count
  Future<List<GroupMembersInfo>> getGroupMemberList({
    required String groupID,
    int filter = 0,
    int offset = 0,
    int count = 0,
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'filter': filter,
      'offset': offset,
      'count': count,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getGroupMemberList', params)
        : _channel.invokeMethod('getGroupMemberList', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupMembersInfo.fromJson(map)),
    );
  }

  /// Paginate and retrieve the group member list as a map
  /// [groupID] Group ID
  /// [filter] Member filter (0: All, 1: Group owner, 2: Administrator, 3: Regular member, 4: Admin + Regular member, 5: Group owner + Admin)
  /// [offset] Starting index
  /// [count] Total count
  Future<List<dynamic>> getGroupMemberListMap({
    required String groupID,
    int filter = 0,
    int offset = 0,
    int count = 0,
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'filter': filter,
      'offset': offset,
      'count': count,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getGroupMemberList', params)
        : _channel.invokeMethod('getGroupMemberList', _buildParam(params));
    return future.then((value) => Utils.toListMap(value));
  }

  /// Query the list of joined groups
  Future<List<GroupInfo>> getJoinedGroupList({String? operationID}) {
    final params = {'operationID': Utils.checkOperationID(operationID)};
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getJoinedGroupList', params)
        : _channel.invokeMethod('getJoinedGroupList', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupInfo.fromJson(map)),
    );
  }

  Future<List<GroupInfo>> getJoinedGroupListPage(
      {String? operationID, int offset = 0, int count = 40}) {
    final params = {
      'offset': offset,
      'count': count,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getJoinedGroupListPage', params)
        : _channel.invokeMethod('getJoinedGroupListPage', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupInfo.fromJson(map)),
    );
  }

  /// Query the list of joined groups
  Future<List<dynamic>> getJoinedGroupListMap({String? operationID}) {
    final params = {'operationID': Utils.checkOperationID(operationID)};
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getJoinedGroupList', params)
        : _channel.invokeMethod('getJoinedGroupList', _buildParam(params));
    return future.then((value) => Utils.toListMap(value));
  }

  /// Check if the user has joined a group
  /// [groupID] Group ID
  Future<bool> isJoinedGroup({
    required String groupID,
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('isJoinGroup', params)
        : _channel.invokeMethod('isJoinGroup', _buildParam(params));
    return future.then((value) => value == true || value == 'true');
  }

  /// Create a new group
  /// [groupInfo] Group information
  /// [memberUserIDs] List of user IDs to add as initial members
  /// [adminUserIDs] List of user IDs to add as administrators
  /// [ownerUserID] User ID of the owner
  Future<GroupInfo> createGroup({
    required GroupInfo groupInfo,
    List<String> memberUserIDs = const [],
    List<String> adminUserIDs = const [],
    String? ownerUserID,
    String? operationID,
  }) {
    final future = _invoke('createGroup', {
      'groupInfo': groupInfo.toJson(),
      'memberUserIDs': memberUserIDs,
      'adminUserIDs': adminUserIDs,
      'ownerUserID': ownerUserID,
      'operationID': Utils.checkOperationID(operationID),
    });
    return future.then(
      (value) => Utils.toObj(value, (map) => GroupInfo.fromJson(map)),
    );
  }

  /// Edit group information
  Future<dynamic> setGroupInfo(
    GroupInfo groupInfo, {
    String? operationID,
  }) {
    return _invoke('setGroupInfo', {
      'groupInfo': groupInfo.toJson(),
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Query group information
  Future<List<GroupInfo>> getGroupsInfo({
    required List<String> groupIDList,
    String? operationID,
  }) {
    final params = {
      'groupIDList': groupIDList,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getGroupsInfo', params)
        : _channel.invokeMethod('getGroupsInfo', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupInfo.fromJson(map)),
    );
  }

  /// Apply to join a group, requiring approval from an administrator or the group.
  /// [joinSource] 2: Invited, 3: Searched, 4: Using a QR code
  Future<dynamic> joinGroup(
      {required String groupID,
      String? reason,
      String? operationID,
      int joinSource = 3,
      String? ex}) {
    return _invoke('joinGroup', {
      'groupID': groupID,
      'reason': reason,
      'joinSource': joinSource,
      'ex': ex,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Exit a group
  Future<dynamic> quitGroup({
    required String groupID,
    String? operationID,
  }) {
    return _invoke('quitGroup', {
      'groupID': groupID,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  // (Continuing the code)

  /// Transfer group ownership
  Future<dynamic> transferGroupOwner({
    required String groupID,
    required String userID,
    String? operationID,
  }) {
    return _invoke('transferGroupOwner', {
      'groupID': groupID,
      'userID': userID,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Handle group membership applications received as a group owner or administrator
  Future<List<GroupApplicationInfo>> getGroupApplicationListAsRecipient({
    GetGroupApplicationListAsRecipientReq? req,
    String? operationID,
  }) {
    if (req != null && req.offset > 0) {
      assert(req.count > 0, 'count must be greater than 0');
    }
    final future = _invoke('getGroupApplicationListAsRecipient', {
      'req': req?.toJson() ?? {},
      "operationID": Utils.checkOperationID(operationID),
    });
    return future.then(
      (value) =>
          Utils.toList(value, (map) => GroupApplicationInfo.fromJson(map)),
    );
  }

  /// Get the list of group membership applications sent by the user
  Future<List<GroupApplicationInfo>> getGroupApplicationListAsApplicant({
    GetGroupApplicationListAsApplicantReq? req,
    String? operationID,
  }) {
    if (req != null && req.offset > 0) {
      assert(req.count > 0, 'count must be greater than 0');
    }

    final future = _invoke('getGroupApplicationListAsApplicant', {
      'req': req?.toJson() ?? {},
      "operationID": Utils.checkOperationID(operationID),
    });
    return future.then(
      (value) =>
          Utils.toList(value, (map) => GroupApplicationInfo.fromJson(map)),
    );
  }

  /// Accept a group membership application as an administrator or group owner
  /// Note: Membership applications require approval from administrators or the group.
  Future<dynamic> acceptGroupApplication({
    required String groupID,
    required String userID,
    String? handleMsg,
    String? operationID,
  }) {
    return _invoke('acceptGroupApplication', {
      'groupID': groupID,
      'userID': userID,
      'handleMsg': handleMsg,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Refuse a group membership application as an administrator or group owner
  /// Note: Membership applications require approval from administrators or the group.
  Future<dynamic> refuseGroupApplication({
    required String groupID,
    required String userID,
    String? handleMsg,
    String? operationID,
  }) {
    return _invoke('refuseGroupApplication', {
      'groupID': groupID,
      'userID': userID,
      'handleMsg': handleMsg,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  // (Continuing the code)

  /// Dissolve a group
  /// [groupID] Group ID
  Future<dynamic> dismissGroup({
    required String groupID,
    String? operationID,
  }) {
    return _invoke('dismissGroup', {
      'groupID': groupID,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Enable or disable group mute, preventing all group members from sending messages
  /// [groupID] Group ID
  /// [mute] true: Enable, false: Disable
  Future<dynamic> changeGroupMute({
    required String groupID,
    required bool mute,
    String? operationID,
  }) {
    return _invoke('changeGroupMute', {
      'groupID': groupID,
      'mute': mute,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Mute a group member
  /// [groupID] Group ID
  /// [userID] Member ID to mute
  /// [seconds] Duration of the mute in seconds (set to 0 to unmute)
  Future<dynamic> changeGroupMemberMute({
    required String groupID,
    required String userID,
    int seconds = 0,
    String? operationID,
  }) {
    return _invoke('changeGroupMemberMute', {
      'groupID': groupID,
      'userID': userID,
      'seconds': seconds,
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  /// Set the nickname of a group member
  /// [groupID] Group ID
  /// [userID] User ID of the group member
  /// [groupNickname] Group nickname
  @Deprecated('Use [setGroupMemberInfo] instead')
  Future<dynamic> setGroupMemberNickname({
    required String groupID,
    required String userID,
    String? groupNickname,
    String? operationID,
  }) {
    final req = SetGroupMemberInfo(
        groupID: groupID, userID: userID, nickname: groupNickname);

    return setGroupMemberInfo(groupMembersInfo: req, operationID: operationID);
  }

  /// Query a group
  /// [keywordList] Search keywords; currently, only one keyword is supported, and it cannot be empty.
  /// [isSearchGroupID] Whether to search by group ID (Note: cannot set both to false at the same time); defaults to false if not set.
  /// [isSearchGroupName] Whether to search by group name; defaults to false if not set.
  Future<List<GroupInfo>> searchGroups({
    List<String> keywordList = const [],
    bool isSearchGroupID = false,
    bool isSearchGroupName = false,
    String? operationID,
  }) {
    final params = {
      'searchParam': {
        'keywordList': keywordList,
        'isSearchGroupID': isSearchGroupID,
        'isSearchGroupName': isSearchGroupName,
      },
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('searchGroups', params)
        : _channel.invokeMethod('searchGroups', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupInfo.fromJson(map)),
    );
  }

  /// Set group member role
  /// [groupID] Group ID
  /// [userID] User ID of the group member
  /// [roleLevel] Role level; see [GroupRoleLevel]
  @Deprecated('Use [setGroupMemberInfo] instead')
  Future<dynamic> setGroupMemberRoleLevel({
    required String groupID,
    required String userID,
    required int roleLevel,
    String? operationID,
  }) {
    final req = SetGroupMemberInfo(
        groupID: groupID, userID: userID, roleLevel: roleLevel);

    return setGroupMemberInfo(groupMembersInfo: req, operationID: operationID);
  }

  /// Get a group member list based on join time
  Future<List<GroupMembersInfo>> getGroupMemberListByJoinTime({
    required String groupID,
    int offset = 0,
    int count = 0,
    int joinTimeBegin = 0,
    int joinTimeEnd = 0,
    List<String> filterUserIDList = const [],
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'offset': offset,
      'count': count,
      'joinTimeBegin': joinTimeBegin,
      'joinTimeEnd': joinTimeEnd,
      'excludeUserIDList': filterUserIDList,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(
            'getGroupMemberListByJoinTimeFilter',
            params,
          )
        : _channel.invokeMethod(
            'getGroupMemberListByJoinTimeFilter',
            _buildParam(params),
          );
    return future.then(
      (value) => Utils.toList(value, (map) => GroupMembersInfo.fromJson(map)),
    );
  }

  /// Set group verification for joining
  /// [groupID] Group ID
  /// [needVerification] Verification setting; see [GroupVerification] class
  @Deprecated('Use [setGroupInfo] instead')
  Future<dynamic> setGroupVerification({
    required String groupID,
    required int needVerification,
    String? operationID,
  }) {
    final req = GroupInfo(groupID: groupID, needVerification: needVerification);

    return setGroupInfo(req, operationID: operationID);
  }

  /// Allow/disallow members to add friends through the group
  /// [groupID] Group ID
  /// [status] 0: Disable, 1: Enable
  @Deprecated('Use [setGroupInfo] instead')
  Future<dynamic> setGroupLookMemberInfo({
    required String groupID,
    required int status,
    String? operationID,
  }) {
    final req = GroupInfo(groupID: groupID, lookMemberInfo: status);

    return setGroupInfo(req, operationID: operationID);
  }

  /// Allow/disallow members to add friends through the group
  /// [groupID] Group ID
  /// [status] 0: Disable, 1: Enable
  @Deprecated('Use [setGroupInfo] instead')
  Future<dynamic> setGroupApplyMemberFriend({
    required String groupID,
    required int status,
    String? operationID,
  }) {
    final req = GroupInfo(groupID: groupID, applyMemberFriend: status);

    return setGroupInfo(req, operationID: operationID);
  }

  /// Get group owners and administrators
  /// [groupId] Group ID
  Future<List<GroupMembersInfo>> getGroupOwnerAndAdmin({
    required String groupID,
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getGroupMemberOwnerAndAdmin', params)
        : _channel.invokeMethod(
            'getGroupMemberOwnerAndAdmin',
            _buildParam(params),
          );
    return future.then(
      (value) => Utils.toList(value, (map) => GroupMembersInfo.fromJson(map)),
    );
  }

  /// Search for group members
  /// [groupID] Group ID
  /// [keywordList] Search keywords; currently, only one keyword is supported, and it cannot be empty.
  /// [isSearchUserID] Whether to search by member ID
  /// [isSearchMemberNickname] Whether to search by member nickname
  /// [offset] Start index
  /// [count] Total count to retrieve
  Future<List<GroupMembersInfo>> searchGroupMembers({
    required String groupID,
    List<String> keywordList = const [],
    bool isSearchUserID = false,
    bool isSearchMemberNickname = false,
    int offset = 0,
    int count = 40,
    String? operationID,
  }) {
    final params = {
      'searchParam': {
        'groupID': groupID,
        'keywordList': keywordList,
        'isSearchUserID': isSearchUserID,
        'isSearchMemberNickname': isSearchMemberNickname,
        'offset': offset,
        'count': count,
      },
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('searchGroupMembers', params)
        : _channel.invokeMethod('searchGroupMembers', _buildParam(params));
    return future.then(
      (value) => Utils.toList(value, (map) => GroupMembersInfo.fromJson(map)),
    );
  }

  /// Query a group
  /// [groupID] Group ID
  /// [keywordList] Search keyword, currently only supports searching with one keyword, and it cannot be empty
  /// [isSearchUserID] Whether to search member IDs with the keyword
  /// [isSearchMemberNickname] Whether to search member nicknames with the keyword
  /// [offset] Starting index
  /// [count] Total number to retrieve each time
  Future<List<dynamic>> searchGroupMembersListMap({
    required String groupID,
    List<String> keywordList = const [],
    bool isSearchUserID = false,
    bool isSearchMemberNickname = false,
    int offset = 0,
    int count = 40,
    String? operationID,
  }) {
    final params = {
      'searchParam': {
        'groupID': groupID,
        'keywordList': keywordList,
        'isSearchUserID': isSearchUserID,
        'isSearchMemberNickname': isSearchMemberNickname,
        'offset': offset,
        'count': count,
      },
      'operationID': Utils.checkOperationID(operationID),
    };
    final future = MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('searchGroupMembers', params)
        : _channel.invokeMethod('searchGroupMembers', _buildParam(params));
    return future.then((value) => Utils.toListMap(value));
  }

  /// Modify the GroupMemberInfo ex field
  Future<dynamic> setGroupMemberInfo({
    required SetGroupMemberInfo groupMembersInfo,
    String? operationID,
  }) {
    return _invoke('setGroupMemberInfo', {
      'info': groupMembersInfo.toJson(),
      'operationID': Utils.checkOperationID(operationID),
    });
  }

  Future<dynamic> getUsersInGroup(
    String groupID,
    List<String> userIDs, {
    String? operationID,
  }) {
    final params = {
      'groupID': groupID,
      'userIDs': userIDs,
      'operationID': Utils.checkOperationID(operationID),
    };
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call('getUsersInGroup', params)
        : _channel.invokeMethod('getUsersInGroup', _buildParam(params));
  }

  Future<int> getGroupApplicationUnhandledCount(
          GetGroupApplicationUnhandledCountReq req,
          {String? operationID}) =>
      _invoke('getGroupApplicationUnhandledCount', {
        'req': req.toJson(),
        'operationID': Utils.checkOperationID(operationID),
      }).then((value) => value is int ? value : int.parse('$value'));

  /// Check whether the local joined-group cache is fully synchronized.
  Future<bool> checkLocalGroupFullSync({String? operationID}) {
    return _invoke('checkLocalGroupFullSync', {
      'operationID': Utils.checkOperationID(operationID),
    }).then((value) => value == true || value == 'true');
  }

  /// Check whether the local member cache of [groupID] is fully synchronized.
  Future<bool> checkGroupMemberFullSync({
    required String groupID,
    String? operationID,
  }) {
    return _invoke('checkGroupMemberFullSync', {
      'groupID': groupID,
      'operationID': Utils.checkOperationID(operationID),
    }).then((value) => value == true || value == 'true');
  }

  Future<dynamic> _invoke(String method, Map<String, dynamic> params) {
    return MacOSOpenIMBridge.instance.isSupported
        ? MacOSOpenIMBridge.instance.call(method, params)
        : _channel.invokeMethod(method, _buildParam(params));
  }

  static Map _buildParam(Map<String, dynamic> param) {
    param["ManagerName"] = "groupManager";
    param = Utils.cleanMap(param);
    log('param: $param');

    return param;
  }
}
