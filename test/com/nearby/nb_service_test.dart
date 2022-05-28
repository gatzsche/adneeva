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
  late NbService advertizerNbService;
  late NbService scannerNbService;

  late MockNearbyService mockAdvertizerNearbyService;
  late MockNearbyService mockScannerNearbyService;

  String lastLoggedMessage = '';
  void writeToLog(String s) {
    lastLoggedMessage = s;
  }

  final sampleData0 = 'Hello World'.uint8List;
  final sampleData1 = 'Hello World'.uint8List;

  final device0 = Device('ScannerDeviceId0', 'Scanner Device Name 0',
      MockNearbyService.notConnected);

  final device1 = Device('ScannerDeviceId1', 'Scanner Device Name 1',
      MockNearbyService.notConnected);

  // ...........................................................................
  void initServices() {
    advertizerNbService = NbService(
      role: EndpointRole.advertizer,
      log: writeToLog,
      service: const NbServiceInfo(),
    );

    scannerNbService = NbService(
      role: EndpointRole.scanner,
      log: writeToLog,
      service: const NbServiceInfo(),
    );
    expect(MockNearbyService.instances.length, 2);
    mockAdvertizerNearbyService = MockNearbyService.instances.first;
    mockScannerNearbyService = MockNearbyService.instances.last;
  }

  // ...........................................................................
  void init() {
    expect(lastLoggedMessage, '');
    initServices();
  }

  // ...........................................................................
  void dispose() {
    advertizerNbService.dispose();
    scannerNbService.dispose();
  }

  /*group(
    'NearbyService Advertizer ',
    (() {
      test('should work correctly', () {
        fakeAsync((fake) {
          // Initialize both services
          init();
          fake.flushMicrotasks();

          // Start advertizer service
          advertizerNbService.start();
          fake.flushMicrotasks();

          // Simulate the discovery of a disconnected device
          mockAdvertizerNearbyService.addDevice(device0);
          fake.flushMicrotasks();

          // No connection should have been created yet,
          // because only browsers are initiating a connection.

          // Now assume the browser connects the device.
          // We are simulating this by

          // Check if a connection has been created for the device
          expect(scannerNbService.connections.value.length, 1);
          final connection = scannerNbService.connections.value.first;

          // Simulate sending data
          connection.sendData(sampleData0);
          fake.flushMicrotasks();
          var lastSentObject = mockAdvertizerNearbyService.sentMessages.last;
          final lastSentDeviceId = lastSentObject.deviceId;
          final lastSentMessage = lastSentObject.data;
          expect(
            lastSentDeviceId,
            (connection.serviceInfo as ResolvedNbServiceInfo).device.deviceId,
          );
          expect(lastSentMessage, sampleData0);

          // Simulate receiving data
          Uint8List? receivedData;
          connection.receiveData.listen((d) => receivedData = d);
          mockAdvertizerNearbyService.dataReceivedController.add({
            'deviceID': device0.deviceId,
            'message': base64Encode(sampleData0),
          });
          fake.flushMicrotasks();
          expect(receivedData, sampleData0);

          // Check second device
          mockAdvertizerNearbyService.addDevice(device1);
          fake.flushMicrotasks();
          expect(scannerNbService.connections.value.length, 2);
          final connection1 = scannerNbService.connections.value.last;
          connection1.sendData(sampleData1);
          fake.flushMicrotasks();
          lastSentObject = mockAdvertizerNearbyService.sentMessages.last;
          expect(lastSentObject.deviceId, device1.deviceId);
          expect(lastSentObject.data, sampleData1);
          Uint8List? receivedData1;
          connection1.receiveData.listen((d) => receivedData1 = d);
          mockAdvertizerNearbyService.dataReceivedController.add({
            'deviceID': device1.deviceId,
            'message': base64Encode(sampleData1),
          });
          fake.flushMicrotasks();
          expect(receivedData1, sampleData1);

          // Disconnect device 0
          mockAdvertizerNearbyService.replaceDevice(
              device0.deviceId, MockNearbyService.notConnected);
          fake.flushMicrotasks();
          expect(scannerNbService.connections.value.length, 1);

          // Device 1 disappears
          mockAdvertizerNearbyService.removeDevice(device1.deviceId);
          fake.flushMicrotasks();
          expect(scannerNbService.connections.value.length, 0);

          dispose();
        });
      });
    }),
  );
  */

  group(
    'NearbyService Scanner',
    (() {
      test('should work correctly', () {
        fakeAsync((fake) {
          // Initialize both services
          init();
          fake.flushMicrotasks();

          // Start scanner service
          scannerNbService.start();
          fake.flushMicrotasks();

          // Simulate the discovery of a disconnected device
          mockScannerNearbyService.addDevice(device0);
          fake.flushMicrotasks();

          // Check if a connection has been created for the device
          expect(scannerNbService.connections.value.length, 1);
          final connection = scannerNbService.connections.value.first;

          // Simulate sending data
          connection.sendData(sampleData0);
          fake.flushMicrotasks();
          var lastSentObject = mockScannerNearbyService.sentMessages.last;
          final lastSentDeviceId = lastSentObject.deviceId;
          final lastSentMessage = lastSentObject.data;
          expect(
            lastSentDeviceId,
            (connection.serviceInfo as ResolvedNbServiceInfo).device.deviceId,
          );
          expect(lastSentMessage, sampleData0);

          // Simulate receiving data
          Uint8List? receivedData;
          connection.receiveData.listen((d) => receivedData = d);
          mockScannerNearbyService.dataReceivedController.add({
            'deviceID': device0.deviceId,
            'message': base64Encode(sampleData0),
          });
          fake.flushMicrotasks();
          expect(receivedData, sampleData0);

          // Check second device
          mockScannerNearbyService.addDevice(device1);
          fake.flushMicrotasks();
          expect(scannerNbService.connections.value.length, 2);
          final connection1 = scannerNbService.connections.value.last;
          connection1.sendData(sampleData1);
          fake.flushMicrotasks();
          lastSentObject = mockScannerNearbyService.sentMessages.last;
          expect(lastSentObject.deviceId, device1.deviceId);
          expect(lastSentObject.data, sampleData1);
          Uint8List? receivedData1;
          connection1.receiveData.listen((d) => receivedData1 = d);
          mockScannerNearbyService.dataReceivedController.add({
            'deviceID': device1.deviceId,
            'message': base64Encode(sampleData1),
          });
          fake.flushMicrotasks();
          expect(receivedData1, sampleData1);

          // Disconnect device 0
          mockScannerNearbyService.replaceDevice(
              device0.deviceId, MockNearbyService.notConnected);
          fake.flushMicrotasks();
          expect(scannerNbService.connections.value.length, 1);

          // Device 1 disappears
          mockScannerNearbyService.removeDevice(device1.deviceId);
          fake.flushMicrotasks();
          expect(scannerNbService.connections.value.length, 0);

          dispose();
        });
      });
    }),
  );
}
