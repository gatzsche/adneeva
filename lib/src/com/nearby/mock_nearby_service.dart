// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:mocktail/mocktail.dart';

class MockSentMessage {
  const MockSentMessage(
    this.deviceId,
    this.data,
  );
  final Uint8List data;
  final String deviceId;
}

class MockNearbyService extends Mock implements NearbyService {
  static const connecting = 1;
  static const connected = 2;
  static const notConnected = 3;

  // ...........................................................................
  MockNearbyService() {
    instances.add(this);
  }

  // ...........................................................................
  static final instances = <MockNearbyService>[];

  // ...........................................................................
  @override
  Future<void> init(
      {required String serviceType,
      required Strategy strategy,
      String? deviceName,
      required Function callback}) async {
    callback(true);
  }

  // ...........................................................................
  final _stateChangeController = StreamController<List<Device>>();

  // ...........................................................................
  final _deviceList = <Device>[];

  // ...........................................................................
  void addDevice(Device device) {
    _deviceList.add(device);
    _stateChangeController.add(_deviceList);
  }

  // ...........................................................................
  void replaceDevice(String deviceId, int state) {
    // Find existing device
    final existingDevice = _deviceList.firstWhere(
      (d) => d.deviceId == deviceId,
    );

    // Create replace device
    final replacedDevice = Device(deviceId, existingDevice.deviceName, state);

    // Replace device
    final index = _deviceList.indexOf(existingDevice);
    _deviceList.replaceRange(index, index + 1, [replacedDevice]);

    // Inform about change
    _stateChangeController.add(_deviceList);
  }

  // ...........................................................................
  void removeDevice(String deviceId) {
    _deviceList.removeWhere((d) => d.deviceId == deviceId);
    _stateChangeController.add(_deviceList);
  }

  // ...........................................................................
  @override
  StreamSubscription stateChangedSubscription(
          {required StateChangedCallback callback}) =>
      _stateChangeController.stream.listen(callback);

  // ...........................................................................
  final dataReceivedController = StreamController<Object>();
  @override
  StreamSubscription dataReceivedSubscription(
          {required DataReceivedCallback callback}) =>
      dataReceivedController.stream.listen(callback);

  // ...........................................................................
  @override
  FutureOr invitePeer({required String deviceID, String? deviceName}) async {
    replaceDevice(deviceID, connecting);
    scheduleMicrotask(() => replaceDevice(deviceID, connected));
  }

  // ...........................................................................
  final sentMessages = <MockSentMessage>[];

  @override
  FutureOr sendMessage(String deviceID, String message) {
    sentMessages.add(MockSentMessage(deviceID, base64Decode(message)));
  }
}
