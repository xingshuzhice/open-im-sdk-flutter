package main

/*
#include <stdlib.h>
typedef void (*OpenIMMacOSEventCallback)(char*);
static inline void OpenIMMacOSEmitEvent(OpenIMMacOSEventCallback callback, char* event) {
	if (callback != NULL) {
		callback(event);
	}
}
*/
import "C"

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"
	"unsafe"

	"github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
	"github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
	"github.com/openimsdk/openim-sdk-core/v3/pkg/ccontext"
	"github.com/openimsdk/tools/errs"
)

type bridgeResponse struct {
	OK      bool   `json:"ok"`
	Data    any    `json:"data,omitempty"`
	ErrCode int32  `json:"errCode,omitempty"`
	ErrMsg  string `json:"errMsg,omitempty"`
}

type bridgeCallback struct {
	done chan bridgeResponse
}

const bridgeCallTimeout = 30 * time.Second

func newBridgeCallback() *bridgeCallback {
	return &bridgeCallback{done: make(chan bridgeResponse, 1)}
}

func (c *bridgeCallback) OnError(errCode int32, errMsg string) {
	c.done <- bridgeResponse{OK: false, ErrCode: errCode, ErrMsg: errMsg}
}

func (c *bridgeCallback) OnSuccess(data string) {
	c.done <- bridgeResponse{OK: true, Data: data}
}

type bridgeSendCallback struct {
	*bridgeCallback
	clientMsgID string
}

func (c *bridgeSendCallback) OnProgress(progress int) {
	if c.clientMsgID == "" {
		return
	}
	emitNativeEvent("msgSendProgressListener", "onProgress", map[string]any{
		"clientMsgID": c.clientMsgID,
		"progress":    progress,
	}, nil)
}

type connListener struct{}

func (connListener) OnConnecting() {
	emitNativeEvent("connectListener", "onConnecting", nil, nil)
}
func (connListener) OnConnectSuccess() {
	emitNativeEvent("connectListener", "onConnectSuccess", nil, nil)
}
func (connListener) OnConnectFailed(errCode int32, errMsg string) {
	emitNativeEvent("connectListener", "onConnectFailed", nil, map[string]any{
		"errCode": errCode,
		"errMsg":  errMsg,
	})
}
func (connListener) OnKickedOffline() {
	emitNativeEvent("connectListener", "onKickedOffline", nil, nil)
}
func (connListener) OnUserTokenExpired() {
	emitNativeEvent("connectListener", "onUserTokenExpired", nil, nil)
}
func (connListener) OnUserTokenInvalid(errMsg string) {
	emitNativeEvent("connectListener", "onUserTokenInvalid", nil, map[string]any{
		"errMsg": errMsg,
	})
}

type advancedMsgListener struct {
	id string
}

func (l advancedMsgListener) OnRecvNewMessage(message string) {
	emitNativeEvent("advancedMsgListener", "onRecvNewMessage", map[string]any{"id": l.id, "message": message}, nil)
}
func (l advancedMsgListener) OnRecvC2CReadReceipt(msgReceiptList string) {
	emitNativeEvent("advancedMsgListener", "onRecvC2CReadReceipt", map[string]any{"id": l.id, "msgReceiptList": msgReceiptList}, nil)
}
func (l advancedMsgListener) OnNewRecvMessageRevoked(messageRevoked string) {
	emitNativeEvent("advancedMsgListener", "onNewRecvMessageRevoked", map[string]any{"id": l.id, "messageRevoked": messageRevoked}, nil)
}
func (l advancedMsgListener) OnRecvOfflineNewMessage(message string) {
	emitNativeEvent("advancedMsgListener", "onRecvOfflineNewMessage", map[string]any{"id": l.id, "message": message}, nil)
}
func (l advancedMsgListener) OnMsgDeleted(message string) {
	emitNativeEvent("advancedMsgListener", "onMsgDeleted", map[string]any{"id": l.id, "message": message}, nil)
}
func (l advancedMsgListener) OnRecvOnlineOnlyMessage(message string) {
	emitNativeEvent("advancedMsgListener", "onRecvOnlineOnlyMessage", map[string]any{"id": l.id, "message": message}, nil)
}

type conversationListener struct{}

func (conversationListener) OnSyncServerStart(reinstalled bool) {
	emitNativeEvent("conversationListener", "onSyncServerStart", reinstalled, nil)
}
func (conversationListener) OnSyncServerFinish(reinstalled bool) {
	emitNativeEvent("conversationListener", "onSyncServerFinish", reinstalled, nil)
}
func (conversationListener) OnSyncServerProgress(progress int) {
	emitNativeEvent("conversationListener", "onSyncServerProgress", progress, nil)
}
func (conversationListener) OnSyncServerFailed(reinstalled bool) {
	emitNativeEvent("conversationListener", "onSyncServerFailed", reinstalled, nil)
}
func (conversationListener) OnNewConversation(conversationList string) {
	emitNativeEvent("conversationListener", "onNewConversation", conversationList, nil)
}
func (conversationListener) OnConversationChanged(conversationList string) {
	emitNativeEvent("conversationListener", "onConversationChanged", conversationList, nil)
}
func (conversationListener) OnTotalUnreadMessageCountChanged(totalUnreadCount int32) {
	emitNativeEvent("conversationListener", "onTotalUnreadMessageCountChanged", totalUnreadCount, nil)
}
func (conversationListener) OnConversationUserInputStatusChanged(change string) {
	emitNativeEvent("conversationListener", "onConversationUserInputStatusChanged", change, nil)
}

type friendshipListener struct{}

func (friendshipListener) OnFriendApplicationAdded(friendApplication string) {
	emitNativeEvent("friendListener", "onFriendApplicationAdded", friendApplication, nil)
}
func (friendshipListener) OnFriendApplicationDeleted(friendApplication string) {
	emitNativeEvent("friendListener", "onFriendApplicationDeleted", friendApplication, nil)
}
func (friendshipListener) OnFriendApplicationAccepted(friendApplication string) {
	emitNativeEvent("friendListener", "onFriendApplicationAccepted", friendApplication, nil)
}
func (friendshipListener) OnFriendApplicationRejected(friendApplication string) {
	emitNativeEvent("friendListener", "onFriendApplicationRejected", friendApplication, nil)
}
func (friendshipListener) OnFriendAdded(friendInfo string) {
	emitNativeEvent("friendListener", "onFriendAdded", friendInfo, nil)
}
func (friendshipListener) OnFriendDeleted(friendInfo string) {
	emitNativeEvent("friendListener", "onFriendDeleted", friendInfo, nil)
}
func (friendshipListener) OnFriendInfoChanged(friendInfo string) {
	emitNativeEvent("friendListener", "onFriendInfoChanged", friendInfo, nil)
}
func (friendshipListener) OnBlackAdded(blackInfo string) {
	emitNativeEvent("friendListener", "onBlackAdded", blackInfo, nil)
}
func (friendshipListener) OnBlackDeleted(blackInfo string) {
	emitNativeEvent("friendListener", "onBlackDeleted", blackInfo, nil)
}

type groupListener struct{}

func (groupListener) OnJoinedGroupAdded(groupInfo string) {
	emitNativeEvent("groupListener", "onJoinedGroupAdded", groupInfo, nil)
}
func (groupListener) OnJoinedGroupDeleted(groupInfo string) {
	emitNativeEvent("groupListener", "onJoinedGroupDeleted", groupInfo, nil)
}
func (groupListener) OnGroupMemberAdded(groupMemberInfo string) {
	emitNativeEvent("groupListener", "onGroupMemberAdded", groupMemberInfo, nil)
}
func (groupListener) OnGroupMemberDeleted(groupMemberInfo string) {
	emitNativeEvent("groupListener", "onGroupMemberDeleted", groupMemberInfo, nil)
}
func (groupListener) OnGroupApplicationAdded(groupApplication string) {
	emitNativeEvent("groupListener", "onGroupApplicationAdded", groupApplication, nil)
}
func (groupListener) OnGroupApplicationDeleted(groupApplication string) {
	emitNativeEvent("groupListener", "onGroupApplicationDeleted", groupApplication, nil)
}
func (groupListener) OnGroupInfoChanged(groupInfo string) {
	emitNativeEvent("groupListener", "onGroupInfoChanged", groupInfo, nil)
}
func (groupListener) OnGroupDismissed(groupInfo string) {
	emitNativeEvent("groupListener", "onGroupDismissed", groupInfo, nil)
}
func (groupListener) OnGroupMemberInfoChanged(groupMemberInfo string) {
	emitNativeEvent("groupListener", "onGroupMemberInfoChanged", groupMemberInfo, nil)
}
func (groupListener) OnGroupApplicationAccepted(groupApplication string) {
	emitNativeEvent("groupListener", "onGroupApplicationAccepted", groupApplication, nil)
}
func (groupListener) OnGroupApplicationRejected(groupApplication string) {
	emitNativeEvent("groupListener", "onGroupApplicationRejected", groupApplication, nil)
}

type userListener struct{}

func (userListener) OnSelfInfoUpdated(userInfo string) {
	emitNativeEvent("userListener", "onSelfInfoUpdated", userInfo, nil)
}
func (userListener) OnUserStatusChanged(userOnlineStatus string) {
	emitNativeEvent("userListener", "onUserStatusChanged", userOnlineStatus, nil)
}

type customBusinessListener struct{}

func (customBusinessListener) OnRecvCustomBusinessMessage(businessMessage string) {
	emitNativeEvent("customBusinessListener", "onRecvCustomBusinessMessage", businessMessage, nil)
}

type uploadLogsProgress struct{}

func (uploadLogsProgress) OnProgress(current int64, size int64) {
	emitNativeEvent("uploadLogsListener", "onProgress", map[string]any{
		"current": current,
		"size":    size,
	}, nil)
}

type uploadFileProgress struct {
	id string
}

func (p uploadFileProgress) Open(size int64) {
	p.emit("open", map[string]any{"size": size})
}
func (p uploadFileProgress) PartSize(partSize int64, num int) {
	p.emit("partSize", map[string]any{"partSize": partSize, "num": num})
}
func (p uploadFileProgress) HashPartProgress(index int, size int64, partHash string) {
	p.emit("hashPartProgress", map[string]any{"index": index, "size": size, "partHash": partHash})
}
func (p uploadFileProgress) HashPartComplete(partsHash string, fileHash string) {
	p.emit("hashPartComplete", map[string]any{"partHash": partsHash, "fileHash": fileHash})
}
func (p uploadFileProgress) UploadID(uploadID string) {
	p.emit("uploadID", map[string]any{"uploadID": uploadID})
}
func (p uploadFileProgress) UploadPartComplete(index int, partSize int64, partHash string) {
	p.emit("uploadPartComplete", map[string]any{"index": index, "partSize": partSize, "partHash": partHash})
}
func (p uploadFileProgress) UploadComplete(fileSize int64, streamSize int64, storageSize int64) {
	p.emit("uploadProgress", map[string]any{"fileSize": fileSize, "streamSize": streamSize, "storageSize": storageSize})
}
func (p uploadFileProgress) Complete(size int64, url string, typ int) {
	p.emit("complete", map[string]any{"size": size, "url": url, "type": typ})
}
func (p uploadFileProgress) emit(eventType string, data map[string]any) {
	if p.id == "" {
		return
	}
	data["id"] = p.id
	emitNativeEvent("uploadFileListener", eventType, data, nil)
}

var eventCallbackState struct {
	sync.RWMutex
	callback C.OpenIMMacOSEventCallback
}

func main() {}

//export OpenIMMacOSCall
func OpenIMMacOSCall(method *C.char, argsJSON *C.char) *C.char {
	methodName := C.GoString(method)
	args := map[string]any{}
	if raw := C.GoString(argsJSON); raw != "" {
		if err := json.Unmarshal([]byte(raw), &args); err != nil {
			return encode(bridgeResponse{OK: false, ErrCode: 1001, ErrMsg: err.Error()})
		}
	}
	resp := dispatch(methodName, args)
	return encode(resp)
}

//export OpenIMMacOSFree
func OpenIMMacOSFree(value *C.char) {
	C.free(unsafe.Pointer(value))
}

//export OpenIMMacOSSetEventCallback
func OpenIMMacOSSetEventCallback(callback C.OpenIMMacOSEventCallback) {
	eventCallbackState.Lock()
	eventCallbackState.callback = callback
	eventCallbackState.Unlock()
}

func dispatch(method string, args map[string]any) bridgeResponse {
	defer func() {
		_ = recover()
	}()

	operationID := stringArg(args, "operationID")
	switch method {
	case "initSDK":
		raw, _ := json.Marshal(args)
		ok := open_im_sdk.InitSDK(connListener{}, operationID, string(raw))
		return bridgeResponse{OK: true, Data: ok}
	case "unInitSDK":
		open_im_sdk.UnInitSDK(operationID)
		return bridgeResponse{OK: true, Data: nil}
	case "login":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.Login(cb, operationID, stringArg(args, "userID"), stringArg(args, "token"))
		})
	case "logout":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.Logout(cb, operationID)
		})
	case "getLoginStatus":
		return bridgeResponse{OK: true, Data: open_im_sdk.GetLoginStatus(operationID)}
	case "getLoginUserID":
		return bridgeResponse{OK: true, Data: open_im_sdk.GetLoginUserID()}
	case "logs":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.Logs(
				cb,
				operationID,
				intArg(args, "logLevel"),
				stringArg(args, "file"),
				intArg(args, "line"),
				stringArg(args, "msgs"),
				stringArg(args, "err"),
				jsonStringArg(args, "keyAndValue"),
			)
		})
	case "uploadLogs":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.UploadLogs(
				cb,
				operationID,
				intArg(args, "line"),
				stringArg(args, "ex"),
				uploadLogsProgress{},
			)
		})
	case "uploadFile":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.UploadFile(
				cb,
				operationID,
				jsonString(args),
				uploadFileProgress{id: stringArg(args, "id")},
			)
		})
	case "getSelfUserInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetSelfUserInfo(cb, operationID)
		})
	case "getUsersInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetUsersInfo(cb, operationID, jsonStringArg(args, "userIDList"))
		})
	case "setSelfInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetSelfInfo(cb, operationID, jsonString(args))
		})
	case "subscribeUsersStatus":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SubscribeUsersStatus(cb, operationID, jsonStringArg(args, "userIDs"))
		})
	case "unsubscribeUsersStatus":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.UnsubscribeUsersStatus(cb, operationID, jsonStringArg(args, "userIDs"))
		})
	case "getSubscribeUsersStatus":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetSubscribeUsersStatus(cb, operationID)
		})
	case "getUserStatus":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetUserStatus(cb, operationID, jsonStringArg(args, "userIDs"))
		})
	case "getConversationListSplit":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetConversationListSplit(cb, operationID, intArg(args, "offset"), intArg(args, "count"))
		})
	case "getAllConversationList":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetAllConversationList(cb, operationID)
		})
	case "getOneConversation":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetOneConversation(
				cb,
				operationID,
				int32(intArg(args, "sessionType")),
				stringArg(args, "sourceID"),
			)
		})
	case "getMultipleConversation":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetMultipleConversation(
				cb,
				operationID,
				jsonStringArg(args, "conversationIDList"),
			)
		})
	case "setConversation":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetConversation(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				jsonStringArg(args, "req"),
			)
		})
	case "setConversationDraft":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetConversationDraft(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				stringArg(args, "draftText"),
			)
		})
	case "hideConversation":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.HideConversation(cb, operationID, stringArg(args, "conversationID"))
		})
	case "hideAllConversations":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.HideAllConversations(cb, operationID)
		})
	case "deleteConversationAndDeleteAllMsg":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DeleteConversationAndDeleteAllMsg(
				cb,
				operationID,
				stringArg(args, "conversationID"),
			)
		})
	case "clearConversationAndDeleteAllMsg":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.ClearConversationAndDeleteAllMsg(
				cb,
				operationID,
				stringArg(args, "conversationID"),
			)
		})
	case "getConversationIDBySessionType":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.GetConversationIDBySessionType(
				operationID,
				stringArg(args, "sourceID"),
				intArg(args, "sessionType"),
			),
		}
	case "getTotalUnreadMsgCount":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetTotalUnreadMsgCount(cb, operationID)
		})
	case "getConversationRecvMessageOpt":
		return bridgeResponse{
			OK:      false,
			ErrCode: 1002,
			ErrMsg:  "macOS OpenIM bridge method not exposed by current openim-sdk-core: getConversationRecvMessageOpt",
		}
	case "getAtAllTag":
		return bridgeResponse{OK: true, Data: open_im_sdk.GetAtAllTag(operationID)}
	case "createTextMessage":
		return bridgeResponse{OK: true, Data: open_im_sdk.CreateTextMessage(operationID, stringArg(args, "text"))}
	case "createAdvancedTextMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateAdvancedTextMessage(
				operationID,
				stringArg(args, "text"),
				jsonStringArg(args, "richMessageInfoList"),
			),
		}
	case "createTextAtMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateTextAtMessage(
				operationID,
				stringArg(args, "text"),
				jsonStringArg(args, "atUserIDList"),
				jsonStringArg(args, "atUserInfoList"),
				jsonStringArg(args, "quoteMessage"),
			),
		}
	case "createImageMessage":
		return bridgeResponse{OK: true, Data: open_im_sdk.CreateImageMessage(operationID, stringArg(args, "imagePath"))}
	case "createImageMessageFromFullPath":
		return bridgeResponse{OK: true, Data: open_im_sdk.CreateImageMessageFromFullPath(operationID, stringArg(args, "imagePath"))}
	case "createSoundMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateSoundMessage(
				operationID,
				stringArg(args, "soundPath"),
				int64(intArg(args, "duration")),
			),
		}
	case "createSoundMessageFromFullPath":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateSoundMessageFromFullPath(
				operationID,
				stringArg(args, "soundPath"),
				int64(intArg(args, "duration")),
			),
		}
	case "createVideoMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateVideoMessage(
				operationID,
				stringArg(args, "videoPath"),
				stringArg(args, "videoType"),
				int64(intArg(args, "duration")),
				stringArg(args, "snapshotPath"),
			),
		}
	case "createVideoMessageFromFullPath":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateVideoMessageFromFullPath(
				operationID,
				stringArg(args, "videoPath"),
				stringArg(args, "videoType"),
				int64(intArg(args, "duration")),
				stringArg(args, "snapshotPath"),
			),
		}
	case "createFileMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateFileMessage(
				operationID,
				stringArg(args, "filePath"),
				stringArg(args, "fileName"),
			),
		}
	case "createFileMessageFromFullPath":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateFileMessageFromFullPath(
				operationID,
				stringArg(args, "filePath"),
				stringArg(args, "fileName"),
			),
		}
	case "createMergerMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateMergerMessage(
				operationID,
				jsonStringArg(args, "messageList"),
				stringArg(args, "title"),
				jsonStringArg(args, "summaryList"),
			),
		}
	case "createQuoteMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateQuoteMessage(
				operationID,
				stringArg(args, "quoteText"),
				jsonStringArg(args, "quoteMessage"),
			),
		}
	case "createAdvancedQuoteMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateAdvancedQuoteMessage(
				operationID,
				stringArg(args, "quoteText"),
				jsonStringArg(args, "quoteMessage"),
				jsonStringArg(args, "richMessageInfoList"),
			),
		}
	case "createLocationMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateLocationMessage(
				operationID,
				stringArg(args, "description"),
				floatArg(args, "longitude"),
				floatArg(args, "latitude"),
			),
		}
	case "createCustomMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateCustomMessage(
				operationID,
				stringArg(args, "data"),
				stringArg(args, "extension"),
				stringArg(args, "description"),
			),
		}
	case "createCardMessage":
		return bridgeResponse{
			OK:   true,
			Data: open_im_sdk.CreateCardMessage(operationID, jsonStringArg(args, "cardMessage")),
		}
	case "createFaceMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateFaceMessage(
				operationID,
				intArg(args, "index"),
				stringArg(args, "data"),
			),
		}
	case "createForwardMessage":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateForwardMessage(
				operationID,
				jsonStringArg(args, "message"),
			),
		}
	case "sendMessage":
		cb := &bridgeSendCallback{
			bridgeCallback: newBridgeCallback(),
			clientMsgID:    stringArg(parseJSONMap(jsonStringArg(args, "message")), "clientMsgID"),
		}
		open_im_sdk.SendMessage(
			cb,
			operationID,
			jsonStringArg(args, "message"),
			stringArg(args, "userID"),
			stringArg(args, "groupID"),
			jsonStringArg(args, "offlinePushInfo"),
			boolArg(args, "isOnlineOnly"),
		)
		return waitCallback(cb.done)
	case "sendMessageNotOss":
		cb := &bridgeSendCallback{
			bridgeCallback: newBridgeCallback(),
			clientMsgID:    stringArg(parseJSONMap(jsonStringArg(args, "message")), "clientMsgID"),
		}
		open_im_sdk.SendMessageNotOss(
			cb,
			operationID,
			jsonStringArg(args, "message"),
			stringArg(args, "userID"),
			stringArg(args, "groupID"),
			jsonStringArg(args, "offlinePushInfo"),
			boolArg(args, "isOnlineOnly"),
		)
		return waitCallback(cb.done)
	case "typingStatusUpdate":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.TypingStatusUpdate(
				cb,
				operationID,
				stringArg(args, "userID"),
				stringArg(args, "msgTip"),
			)
		})
	case "deleteMessageFromLocalStorage":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DeleteMessageFromLocalStorage(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				stringArg(args, "clientMsgID"),
			)
		})
	case "deleteMessageFromLocalAndSvr":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DeleteMessage(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				stringArg(args, "clientMsgID"),
			)
		})
	case "revokeMessage":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.RevokeMessage(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				stringArg(args, "clientMsgID"),
			)
		})
	case "deleteAllMsgFromLocal":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DeleteAllMsgFromLocal(cb, operationID)
		})
	case "deleteAllMsgFromLocalAndSvr":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DeleteAllMsgFromLocalAndSvr(cb, operationID)
		})
	case "insertSingleMessageToLocalStorage":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.InsertSingleMessageToLocalStorage(
				cb,
				operationID,
				jsonStringArg(args, "message"),
				stringArg(args, "receiverID"),
				stringArg(args, "senderID"),
			)
		})
	case "insertGroupMessageToLocalStorage":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.InsertGroupMessageToLocalStorage(
				cb,
				operationID,
				jsonStringArg(args, "message"),
				stringArg(args, "groupID"),
				stringArg(args, "senderID"),
			)
		})
	case "getAdvancedHistoryMessageList":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetAdvancedHistoryMessageList(
				cb,
				operationID,
				jsonString(args),
			)
		})
	case "getAdvancedHistoryMessageListReverse":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetAdvancedHistoryMessageListReverse(
				cb,
				operationID,
				jsonString(args),
			)
		})
	case "searchLocalMessages":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SearchLocalMessages(
				cb,
				operationID,
				jsonStringArg(args, "filter"),
			)
		})
	case "findMessageList":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.FindMessageList(
				cb,
				operationID,
				jsonStringArg(args, "searchParams"),
			)
		})
	case "markConversationMessageAsRead":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.MarkConversationMessageAsRead(
				cb,
				operationID,
				stringArg(args, "conversationID"),
			)
		})
	case "markMessagesAsReadByMsgID":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.MarkMessagesAsReadByMsgID(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				jsonStringArg(args, "messageIDList"),
			)
		})
	case "setMessageLocalEx":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetMessageLocalEx(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				stringArg(args, "clientMsgID"),
				stringArg(args, "localEx"),
			)
		})
	case "updateFcmToken":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.UpdateFcmToken(
				cb,
				operationID,
				stringArg(args, "fcmToken"),
				int64(intArg(args, "expireTime")),
			)
		})
	case "setAppBadge":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetAppBadge(
				cb,
				operationID,
				int32(intArg(args, "count")),
			)
		})
	case "createImageMessageByURL":
		return bridgeResponse{
			OK: true,
			Data: open_im_sdk.CreateImageMessageByURL(
				operationID,
				stringArg(args, "sourcePath"),
				jsonStringArg(args, "sourcePicture"),
				jsonStringArg(args, "bigPicture"),
				jsonStringArg(args, "snapshotPicture"),
			),
		}
	case "createSoundMessageByURL":
		return bridgeResponse{
			OK:   true,
			Data: open_im_sdk.CreateSoundMessageByURL(operationID, jsonStringArg(args, "soundElem")),
		}
	case "createVideoMessageByURL":
		return bridgeResponse{
			OK:   true,
			Data: open_im_sdk.CreateVideoMessageByURL(operationID, jsonStringArg(args, "videoElem")),
		}
	case "createFileMessageByURL":
		return bridgeResponse{
			OK:   true,
			Data: open_im_sdk.CreateFileMessageByURL(operationID, jsonStringArg(args, "fileElem")),
		}
	case "searchConversations":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SearchConversation(cb, operationID, stringArg(args, "name"))
		})
	case "changeInputStates":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.ChangeInputStates(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				boolArg(args, "focus"),
			)
		})
	case "getInputStates":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetInputStates(
				cb,
				operationID,
				stringArg(args, "conversationID"),
				stringArg(args, "userID"),
			)
		})
	case "getGroupMembersInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetSpecifiedGroupMembersInfo(
				cb,
				operationID,
				stringArg(args, "groupID"),
				jsonStringArg(args, "userIDList"),
			)
		})
	case "getGroupMemberList":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetGroupMemberList(
				cb,
				operationID,
				stringArg(args, "groupID"),
				int32(intArg(args, "filter")),
				int32(intArg(args, "offset")),
				int32(intArg(args, "count")),
			)
		})
	case "createGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.CreateGroup(cb, operationID, jsonString(args))
		})
	case "setGroupInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetGroupInfo(cb, operationID, jsonStringArg(args, "groupInfo"))
		})
	case "joinGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.JoinGroup(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "reason"),
				int32(intArg(args, "joinSource")),
				stringArg(args, "ex"),
			)
		})
	case "quitGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.QuitGroup(cb, operationID, stringArg(args, "groupID"))
		})
	case "transferGroupOwner":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.TransferGroupOwner(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "userID"),
			)
		})
	case "getGroupApplicationListAsRecipient":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetGroupApplicationListAsRecipient(cb, operationID, jsonStringArg(args, "req"))
		})
	case "getGroupApplicationListAsApplicant":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetGroupApplicationListAsApplicant(cb, operationID, jsonStringArg(args, "req"))
		})
	case "acceptGroupApplication":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.AcceptGroupApplication(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "userID"),
				stringArg(args, "handleMsg"),
			)
		})
	case "refuseGroupApplication":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.RefuseGroupApplication(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "userID"),
				stringArg(args, "handleMsg"),
			)
		})
	case "dismissGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DismissGroup(cb, operationID, stringArg(args, "groupID"))
		})
	case "changeGroupMute":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.ChangeGroupMute(
				cb,
				operationID,
				stringArg(args, "groupID"),
				boolArg(args, "mute"),
			)
		})
	case "changeGroupMemberMute":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.ChangeGroupMemberMute(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "userID"),
				intArg(args, "seconds"),
			)
		})
	case "getJoinedGroupList":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetJoinedGroupList(cb, operationID)
		})
	case "getJoinedGroupListPage":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetJoinedGroupListPage(
				cb,
				operationID,
				int32(intArg(args, "offset")),
				int32(intArg(args, "count")),
			)
		})
	case "getGroupsInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetSpecifiedGroupsInfo(
				cb,
				operationID,
				jsonStringArg(args, "groupIDList"),
			)
		})
	case "isJoinGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.IsJoinGroup(cb, operationID, stringArg(args, "groupID"))
		})
	case "searchGroups":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SearchGroups(cb, operationID, jsonStringArg(args, "searchParam"))
		})
	case "getGroupMemberListByJoinTimeFilter":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetGroupMemberListByJoinTimeFilter(
				cb,
				operationID,
				stringArg(args, "groupID"),
				int32(intArg(args, "offset")),
				int32(intArg(args, "count")),
				int64(intArg(args, "joinTimeBegin")),
				int64(intArg(args, "joinTimeEnd")),
				jsonStringArg(args, "excludeUserIDList"),
			)
		})
	case "getGroupMemberOwnerAndAdmin":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetGroupMemberOwnerAndAdmin(cb, operationID, stringArg(args, "groupID"))
		})
	case "checkLocalGroupFullSync":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.CheckLocalGroupFullSync(cb, operationID)
		})
	case "checkGroupMemberFullSync":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.CheckGroupMemberFullSync(cb, operationID, stringArg(args, "groupID"))
		})
	case "searchGroupMembers":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SearchGroupMembers(cb, operationID, jsonStringArg(args, "searchParam"))
		})
	case "getUsersInGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetUsersInGroup(
				cb,
				operationID,
				stringArg(args, "groupID"),
				jsonStringArg(args, "userIDs"),
			)
		})
	case "inviteUserToGroup":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.InviteUserToGroup(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "reason"),
				jsonStringArg(args, "userIDList"),
			)
		})
	case "kickGroupMember":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.KickGroupMember(
				cb,
				operationID,
				stringArg(args, "groupID"),
				stringArg(args, "reason"),
				jsonStringArg(args, "userIDList"),
			)
		})
	case "setGroupMemberInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SetGroupMemberInfo(cb, operationID, jsonStringArg(args, "info"))
		})
	case "getGroupApplicationUnhandledCount":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetGroupApplicationUnhandledCount(cb, operationID, jsonStringArg(args, "req"))
		})
	case "getFriendsInfo":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetSpecifiedFriendsInfo(
				cb,
				operationID,
				jsonStringArg(args, "userIDList"),
				boolArg(args, "filterBlack"),
			)
		})
	case "getFriendList":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetFriendList(cb, operationID, boolArg(args, "filterBlack"))
		})
	case "getFriendListPage":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetFriendListPage(
				cb,
				operationID,
				int32(intArg(args, "offset")),
				int32(intArg(args, "count")),
				boolArg(args, "filterBlack"),
			)
		})
	case "getBlacklist":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetBlackList(cb, operationID)
		})
	case "checkFriend":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.CheckFriend(cb, operationID, jsonStringArg(args, "userIDList"))
		})
	case "searchFriends":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.SearchFriends(cb, operationID, jsonStringArg(args, "searchParam"))
		})
	case "addFriend":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.AddFriend(cb, operationID, jsonString(args))
		})
	case "getFriendApplicationListAsRecipient":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetFriendApplicationListAsRecipient(cb, operationID, jsonStringArg(args, "req"))
		})
	case "getFriendApplicationListAsApplicant":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetFriendApplicationListAsApplicant(cb, operationID, jsonStringArg(args, "req"))
		})
	case "addBlacklist":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.AddBlack(
				cb,
				operationID,
				stringArg(args, "userID"),
				stringArg(args, "ex"),
			)
		})
	case "removeBlacklist":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.RemoveBlack(cb, operationID, stringArg(args, "userID"))
		})
	case "deleteFriend":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.DeleteFriend(cb, operationID, stringArg(args, "userID"))
		})
	case "acceptFriendApplication":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.AcceptFriendApplication(cb, operationID, jsonString(args))
		})
	case "refuseFriendApplication":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.RefuseFriendApplication(cb, operationID, jsonString(args))
		})
	case "updateFriends":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.UpdateFriends(cb, operationID, jsonStringArg(args, "req"))
		})
	case "getFriendApplicationUnhandledCount":
		return callBase(func(cb open_im_sdk_callback.Base) {
			open_im_sdk.GetFriendApplicationUnhandledCount(cb, operationID, jsonStringArg(args, "req"))
		})
	case "setUserListener":
		open_im_sdk.SetUserListener(userListener{})
		return bridgeResponse{OK: true, Data: nil}
	case "setAdvancedMsgListener":
		open_im_sdk.SetAdvancedMsgListener(advancedMsgListener{id: stringArg(args, "id")})
		return bridgeResponse{OK: true, Data: nil}
	case "setConversationListener":
		open_im_sdk.SetConversationListener(conversationListener{})
		return bridgeResponse{OK: true, Data: nil}
	case "setFriendshipListener":
		open_im_sdk.SetFriendListener(friendshipListener{})
		return bridgeResponse{OK: true, Data: nil}
	case "setGroupListener":
		open_im_sdk.SetGroupListener(groupListener{})
		return bridgeResponse{OK: true, Data: nil}
	case "setCustomBusinessListener":
		open_im_sdk.SetCustomBusinessListener(customBusinessListener{})
		return bridgeResponse{OK: true, Data: nil}
	case "setUploadLogsListener",
		"setUploadFileListener":
		return bridgeResponse{OK: true, Data: nil}
	default:
		return bridgeResponse{OK: false, ErrCode: 1002, ErrMsg: "macOS OpenIM method not implemented: " + method}
	}
}

func callBase(fn func(open_im_sdk_callback.Base)) bridgeResponse {
	cb := newBridgeCallback()
	fn(cb)
	return waitCallback(cb.done)
}

func waitCallback(done <-chan bridgeResponse) bridgeResponse {
	select {
	case resp := <-done:
		return resp
	case <-time.After(bridgeCallTimeout):
		return bridgeResponse{OK: false, ErrCode: 10001, ErrMsg: "macOS OpenIM bridge call timeout"}
	}
}

func encode(resp bridgeResponse) *C.char {
	if !resp.OK && resp.ErrMsg == "" {
		resp.ErrCode = 1000
		resp.ErrMsg = "unknown macOS bridge error"
	}
	raw, err := json.Marshal(resp)
	if err != nil {
		raw = []byte(fmt.Sprintf(`{"ok":false,"errCode":1000,"errMsg":%q}`, err.Error()))
	}
	return C.CString(string(raw))
}

func emitNativeEvent(method string, eventType string, data any, extra map[string]any) {
	eventCallbackState.RLock()
	callback := eventCallbackState.callback
	eventCallbackState.RUnlock()
	if callback == nil {
		return
	}
	arguments := map[string]any{
		"type": eventType,
		"data": data,
	}
	for key, value := range extra {
		arguments[key] = value
	}
	payload := map[string]any{
		"method":    method,
		"arguments": arguments,
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		return
	}
	C.OpenIMMacOSEmitEvent(callback, C.CString(string(raw)))
}

func operationContext(operationID string) context.Context {
	return ccontext.WithOperationID(context.Background(), operationID)
}

func wrapError(err error) bridgeResponse {
	if err == nil {
		return bridgeResponse{OK: true}
	}
	if code, ok := errs.Unwrap(err).(errs.CodeError); ok {
		return bridgeResponse{OK: false, ErrCode: int32(code.Code()), ErrMsg: err.Error()}
	}
	return bridgeResponse{OK: false, ErrCode: 1000, ErrMsg: err.Error()}
}

func stringArg(args map[string]any, key string) string {
	if value, ok := args[key].(string); ok {
		return value
	}
	return ""
}

func parseJSONMap(value string) map[string]any {
	if value == "" {
		return map[string]any{}
	}
	data := map[string]any{}
	if err := json.Unmarshal([]byte(value), &data); err != nil {
		return map[string]any{}
	}
	return data
}

func intArg(args map[string]any, key string) int {
	switch value := args[key].(type) {
	case float64:
		return int(value)
	case int:
		return value
	case json.Number:
		i, _ := value.Int64()
		return int(i)
	default:
		return 0
	}
}

func floatArg(args map[string]any, key string) float64 {
	switch value := args[key].(type) {
	case float64:
		return value
	case int:
		return float64(value)
	case json.Number:
		f, _ := value.Float64()
		return f
	default:
		return 0
	}
}

func boolArg(args map[string]any, key string) bool {
	if value, ok := args[key].(bool); ok {
		return value
	}
	return false
}

func jsonStringArg(args map[string]any, key string) string {
	value, ok := args[key]
	if !ok || value == nil {
		return ""
	}
	if raw, ok := value.(string); ok {
		return raw
	}
	data, err := json.Marshal(value)
	if err != nil {
		return ""
	}
	return string(data)
}

func jsonString(value any) string {
	data, err := json.Marshal(value)
	if err != nil {
		return ""
	}
	return string(data)
}

var _ = operationContext
var _ = wrapError
