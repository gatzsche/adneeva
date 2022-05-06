// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';

class MockSocket extends Mock implements Socket {
  static Future<Socket> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) async {
    return MockSocket();
  }

  // ...........................................................................
  final dataIn = StreamController<Uint8List>.broadcast();
  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return dataIn.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // ...........................................................................
  // Mock sending data
  @override
  void add(List<int> data) {
    dataIn.add(Uint8List.fromList(data));
  }

  @override
  Stream<Uint8List> asBroadcastStream(
      {void Function(StreamSubscription<Uint8List> subscription)? onListen,
      void Function(StreamSubscription<Uint8List> subscription)? onCancel}) {
    return this;
  }

  // ...........................................................................
  @override
  Future close() async {
    dataIn.close();
  }
}
