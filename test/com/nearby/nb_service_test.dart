// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/nearby/mock_nearby_service.dart';
import 'package:mobile_network_evaluator/src/com/nearby/nb_service.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';
import 'package:mobile_network_evaluator/src/utils/utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late NbService master;
  late NbService slave;

  late MockNearbyService mockMasterNearbyService;
  late MockNearbyService mockSlaveNearbyService;

  String lastLoggedMessage = '';
  void writeToLog(String s) {
    lastLoggedMessage = s;
  }

  final sampleData0 = 'Hello World'.uint8List;
  final sampleData1 = 'Hello World'.uint8List;

  final device0 = Device(
      'SlaveDeviceId0', 'Slave Device Name 0', MockNearbyService.notConnected);

  final device1 = Device(
      'SlaveDeviceId1', 'Slave Device Name 1', MockNearbyService.notConnected);

  // ...........................................................................
  void initMocks() {
    master = NbService(
      role: EndpointRole.master,
      log: writeToLog,
      service: const NbServiceInfo(),
    );
    slave = NbService(
      role: EndpointRole.slave,
      log: writeToLog,
      service: const NbServiceInfo(),
    );
    expect(MockNearbyService.instances.length, 2);
    mockMasterNearbyService = MockNearbyService.instances.first;
    mockSlaveNearbyService = MockNearbyService.instances.last;
  }

  // ...........................................................................
  void init() {
    expect(lastLoggedMessage, '');
    initMocks();
  }

  // ...........................................................................
  void dispose() {
    master.dispose();
    slave.dispose();
  }

  group(
    'NearbyService',
    (() {
      test('should work correctly', () {
        fakeAsync((fake) {
          // Initialize both services
          init();
          fake.flushMicrotasks();

          // Start master as well slave service
          master.start();
          slave.start();
          fake.flushMicrotasks();

          // Simulate the discovery of a disconnected device
          mockSlaveNearbyService.addDevice(device0);
          fake.flushMicrotasks();

          // Check if a connection has been created for the device
          expect(slave.connections.value.length, 1);
          final connection = slave.connections.value.first;

          // Simulate sending data
          connection.sendData(sampleData0);
          fake.flushMicrotasks();
          var lastSentObject = mockSlaveNearbyService.sentMessages.last;
          final lastSentDeviceId = lastSentObject.deviceId;
          final lastSentMessage = lastSentObject.data;
          expect(lastSentDeviceId, connection.serviceInfo.device.deviceId);
          expect(lastSentMessage, sampleData0);

          // Simulate receiving data
          Uint8List? receivedData;
          connection.receiveData.listen((d) => receivedData = d);
          mockSlaveNearbyService.dataReceivedController.add({
            'deviceID': device0.deviceId,
            'message': base64Encode(sampleData0),
          });
          fake.flushMicrotasks();
          expect(receivedData, sampleData0);

          // Check second device
          mockSlaveNearbyService.addDevice(device1);
          fake.flushMicrotasks();
          expect(slave.connections.value.length, 2);
          final connection1 = slave.connections.value.last;
          connection1.sendData(sampleData1);
          fake.flushMicrotasks();
          lastSentObject = mockSlaveNearbyService.sentMessages.last;
          expect(lastSentObject.deviceId, device1.deviceId);
          expect(lastSentObject.data, sampleData1);
          Uint8List? receivedData1;
          connection1.receiveData.listen((d) => receivedData1 = d);
          mockSlaveNearbyService.dataReceivedController.add({
            'deviceID': device1.deviceId,
            'message': base64Encode(sampleData1),
          });
          fake.flushMicrotasks();
          expect(receivedData1, sampleData1);

          // Disconnect device 0
          mockSlaveNearbyService.replaceDevice(
              device0.deviceId, MockNearbyService.notConnected);
          fake.flushMicrotasks();
          expect(slave.connections.value.length, 1);

          // Device 1 disappears
          mockSlaveNearbyService.removeDevice(device1.deviceId);
          fake.flushMicrotasks();
          expect(slave.connections.value.length, 0);

          dispose();
        });
      });
    }),
  );
}
