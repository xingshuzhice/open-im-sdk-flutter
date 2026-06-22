import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('IMManager 高级消息监听兼容 core 批量新消息回调', () async {
    const channelName = 'openim_sdk_flutter_test_batch_messages';
    const channel = MethodChannel(channelName);
    final manager = IMManager(channel);
    final received = <Message>[];
    manager.messageManager.msgListener = OnAdvancedMsgListener(
      onRecvOnlineOnlyMessage: received.add,
    );

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channelName,
      const StandardMethodCodec().encodeMethodCall(MethodCall(
        ListenerType.advancedMsgListener,
        {
          'type': 'onRecvOnlineOnlyMessage',
          'data': {
            'message': jsonEncode([
              _messageJson('m1', 'one'),
              _messageJson('m2', 'two'),
            ]),
          },
        },
      )),
      (_) {},
    );

    expect(received.map((message) => message.clientMsgID), ['m1', 'm2']);
    expect(received.map((message) => message.textElem?.content), [
      'one',
      'two',
    ]);
  });
}

Map<String, dynamic> _messageJson(String clientMsgID, String text) {
  return {
    'clientMsgID': clientMsgID,
    'sendID': 'u2',
    'recvID': 'u1',
    'contentType': MessageType.text,
    'sessionType': ConversationType.single,
    'textElem': {'content': text},
  };
}
