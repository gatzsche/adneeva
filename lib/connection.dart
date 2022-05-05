// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'network_service.dart';

typedef SendStringFunction = Future<void> Function(String);
typedef ConnectFunction = Future<void> Function();
typedef DisconnetFunction = Future<void> Function();

class Connection {
  Connection({
    required this.parentService,
    required this.sendString,
    required this.receiveData,
    required DisconnetFunction disconnect,
  }) : _disconnect = disconnect {
    parentService.addConnection(this);
  }

  final SendStringFunction sendString;
  final Stream<Uint8List> receiveData;
  final NetworkService parentService;

  // ...........................................................................
  Future<void> disconnect() async {
    parentService.removeConnection(this);
    await _disconnect();
  }

  // ######################
  // Private
  // ######################

  final DisconnetFunction _disconnect;
}
