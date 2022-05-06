// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:typed_data';

import '../fake/fake_service.dart';
import 'network_service.dart';

typedef SendDataFunction = Future<void> Function(Uint8List);
typedef ConnectFunction = Future<void> Function();
typedef DisconnectFunction = Future<void> Function();

class Connection<ServiceDescription> {
  Connection({
    required this.parentService,
    required this.sendData,
    required this.receiveData,
    required DisconnectFunction disconnect,
    required this.serviceInfo,
  }) : _disconnect = disconnect {
    parentService.addConnection(this);
  }

  final SendDataFunction sendData;
  final Stream<Uint8List> receiveData;
  final NetworkService parentService;
  final ServiceDescription serviceInfo;

  // ...........................................................................
  void sendString(String string) {
    final uint8List = Uint8List.fromList(string.codeUnits);
    sendData(uint8List);
  }

  // ...........................................................................
  Future<void> disconnect() async {
    if (_isDisconnected) {
      return;
    }
    _isDisconnected = true;
    parentService.removeConnection(this);
    await _disconnect();
  }

  // ######################
  // Private
  // ######################

  final DisconnectFunction _disconnect;
  bool _isDisconnected = false;
}

// #############################################################################
class ExampleServiceDescription {
  const ExampleServiceDescription();
}

Connection exampleConnection({
  NetworkService? parentService,
  SendDataFunction? sendData,
  Stream<Uint8List>? receiveData,
  DisconnectFunction? disconnect,
}) {
  return Connection(
    parentService: parentService ?? FakeService.master,
    sendData: sendData ?? (data) async {},
    receiveData: receiveData ?? StreamController<Uint8List>.broadcast().stream,
    disconnect: disconnect ?? () async {},
    serviceInfo: const ExampleServiceDescription(),
  );
}
