// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';

class MockServerSocket extends Mock implements ServerSocket {
  // ...........................................................................
  static Future<ServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return Future.value(MockServerSocket());
  }

  // ...........................................................................
  // Mock the connection of sockets
  final connectedSocketsIn = StreamController<Socket>.broadcast();

  @override
  StreamSubscription<Socket> listen(void Function(Socket event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return connectedSocketsIn.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  // ...........................................................................
  // Close the server socket
  @override
  Future<ServerSocket> close() async {
    return this;
  }
}
