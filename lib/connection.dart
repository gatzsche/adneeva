// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:typed_data';

import 'network_service.dart';

typedef SendDataFunction = Future<void> Function(Uint8List);
typedef ConnectFunction = Future<void> Function();
typedef DisconnetFunction = Future<void> Function();

class Connection {
  Connection({
    required this.parentService,
    required this.sendData,
    required this.receiveData,
    required DisconnetFunction disconnect,
  }) : _disconnect = disconnect {
    parentService.addConnection(this);
    _listenToReceiveData();
  }

  final SendDataFunction sendData;
  final Stream<Uint8List> receiveData;
  final NetworkService parentService;

  // ...........................................................................
  Future<void> disconnect() async {
    if (_isDisconnected) {
      return;
    }
    _isDisconnected = true;
    parentService.removeConnection(this);
    _subscription?.cancel();
    await _disconnect();
  }

  // ######################
  // Private
  // ######################

  final DisconnetFunction _disconnect;
  bool _isDisconnected = false;

  // ...........................................................................
  StreamSubscription? _subscription;
  void _listenToReceiveData() {
    _subscription = receiveData.listen(
      (_) {},
      onDone: () {
        disconnect();
      },
      // coverage:ignore-start
      onError: (_) {
        disconnect();
      },
      // coverage:ignore-end
    );
  }
}
