import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

typedef _NativeCall = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _DartCall = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _NativeFree = Void Function(Pointer<Utf8>);
typedef _DartFree = void Function(Pointer<Utf8>);
typedef _NativeEventCallback = Void Function(Pointer<Utf8>);
typedef _NativeSetEventCallback = Void Function(Pointer<Void>);
typedef _DartSetEventCallback = void Function(Pointer<Void>);

class MacOSOpenIMBridge {
  MacOSOpenIMBridge._();

  static final MacOSOpenIMBridge instance = MacOSOpenIMBridge._();

  _DartCall? _call;
  _DartFree? _free;
  _DartSetEventCallback? _setEventCallback;
  NativeCallable<_NativeEventCallback>? _eventCallback;
  Future<dynamic> Function(MethodCall call)? _eventHandler;

  bool get isSupported => Platform.isMacOS;

  void registerEventHandler(Future<dynamic> Function(MethodCall call) handler) {
    _eventHandler = handler;
    if (isSupported) {
      _ensureEventCallbackRegistered();
    }
  }

  Future<dynamic> call(String method, Map<String, dynamic> args) async {
    _ensureEventCallbackRegistered();
    final nativeCall = _call ??=
        _library.lookupFunction<_NativeCall, _DartCall>('OpenIMMacOSCall');
    final nativeFree = _free ??=
        _library.lookupFunction<_NativeFree, _DartFree>('OpenIMMacOSFree');
    final methodPtr = method.toNativeUtf8();
    final argsPtr = jsonEncode(args).toNativeUtf8();
    Pointer<Utf8> resultPtr = nullptr;
    try {
      resultPtr = nativeCall(methodPtr, argsPtr);
      final raw = resultPtr.toDartString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['ok'] == true) {
        return map['data'];
      }
      throw PlatformException(
        code: '${map['errCode'] ?? 'macos_bridge_error'}',
        message: map['errMsg']?.toString(),
      );
    } finally {
      malloc.free(methodPtr);
      malloc.free(argsPtr);
      if (resultPtr != nullptr) {
        nativeFree(resultPtr);
      }
    }
  }

  void _ensureEventCallbackRegistered() {
    if (_eventCallback != null) {
      return;
    }
    final callback = NativeCallable<_NativeEventCallback>.listener(
      _handleNativeEvent,
    );
    final setEventCallback = _setEventCallback ??=
        _library.lookupFunction<_NativeSetEventCallback, _DartSetEventCallback>(
      'OpenIMMacOSSetEventCallback',
    );
    setEventCallback(callback.nativeFunction.cast<Void>());
    _eventCallback = callback;
  }

  static void _handleNativeEvent(Pointer<Utf8> eventPtr) {
    if (eventPtr == nullptr) {
      return;
    }
    final bridge = MacOSOpenIMBridge.instance;
    final nativeFree =
        bridge._free ??= bridge._library.lookupFunction<_NativeFree, _DartFree>(
      'OpenIMMacOSFree',
    );
    try {
      final raw = eventPtr.toDartString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final method = map['method']?.toString();
      if (method == null || method.isEmpty) {
        return;
      }
      final arguments = map['arguments'];
      bridge._eventHandler?.call(MethodCall(method, arguments));
    } finally {
      nativeFree(eventPtr);
    }
  }

  DynamicLibrary get _library {
    const name = 'libopenim_macos_bridge.dylib';
    final candidates = <String>[
      name,
      '${File(Platform.resolvedExecutable).parent.path}/../Frameworks/$name',
      '${File(Platform.resolvedExecutable).parent.path}/../Resources/$name',
      '${Directory.current.path}/macos/Pods/flutter_openim_sdk/Libraries/$name',
      '${Directory.current.path}/packages/openim_sdk_flutter/macos/Libraries/$name',
    ];
    for (final path in candidates) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {}
    }
    return DynamicLibrary.open(name);
  }
}
