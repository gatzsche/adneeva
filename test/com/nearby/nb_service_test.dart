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
import 'package:mobile_network_evaluator/src/com/nearby/mock_nb_service.dart';
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

  final disconnectedDevice0 = Device('ScannerDeviceId0',
      'Scanner Device Name 0', MockNearbyService.notConnected);

  final connectedDevice0 = Device(
    disconnectedDevice0.deviceId,
    disconnectedDevice0.deviceName,
    MockNearbyService.connected,
  );

  final disconnectedDevice1 = Device('ScannerDeviceId1',
      'Scanner Device Name 1', MockNearbyService.notConnected);

  // ...........................................................................
  void initServices() {
    advertizerNbService = NbService(
      role: EndpointRole.advertizer,
      log: writeToLog,
      service: serviceInfo,
    );

    scannerNbService = NbService(
      role: EndpointRole.scanner,
      log: writeToLog,
      service: serviceInfo,
    );
    expect(MockNearbyService.instances.length, 2);
    mockAdvertizerNearbyService = MockNearbyService.instances.first;
    mockScannerNearbyService = MockNearbyService.instances.last;
  }

  // ...........................................................................
  void init() {
    MockNearbyService.instances.clear();
    expect(lastLoggedMessage, '');
    initServices();
  }

  // ...........................................................................
  void dispose() {
    advertizerNbService.dispose();
    scannerNbService.dispose();
  }

  group(
    'NearbyService Advertizer ',
    (() {
      test('should work correctly', () {
        fakeAsync((fake) {
          // Initialize
          init();
          fake.flushMicrotasks();

          // Start advertizer service
          advertizerNbService.start();
          fake.flushMicrotasks();

          // Simulate the discovery of a disconnected device
          // No connection should have been created yet,
          // because only scanners are initiating a connection.
          expect(disconnectedDevice0.state, SessionState.notConnected);
          mockAdvertizerNearbyService.addDevice(disconnectedDevice0);
          fake.flushMicrotasks();
          expect(advertizerNbService.connectedEndpoints.value.length, 0);

          // Now the scanner on the other side connects.
          // A connected device will arrive a the advertizer.
          // Advertizer creates an endpoint for that connected device.
          mockAdvertizerNearbyService.addDevice(connectedDevice0);
          fake.flushMicrotasks();
          expect(advertizerNbService.connectedEndpoints.value.length, 1);

          dispose();
        });
      });
    }),
  );

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
          mockScannerNearbyService.addDevice(disconnectedDevice0);
          fake.flushMicrotasks();

          // Check if a connection has been created for the device
          expect(scannerNbService.connectedEndpoints.value.length, 1);
          final connection = scannerNbService.connectedEndpoints.value.first;

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
            'deviceID': disconnectedDevice0.deviceId,
            'message': base64Encode(sampleData0),
          });
          fake.flushMicrotasks();
          expect(receivedData, sampleData0);

          // Check second device
          mockScannerNearbyService.addDevice(disconnectedDevice1);
          fake.flushMicrotasks();
          expect(scannerNbService.connectedEndpoints.value.length, 2);
          final connection1 = scannerNbService.connectedEndpoints.value.last;
          connection1.sendData(sampleData1);
          fake.flushMicrotasks();
          lastSentObject = mockScannerNearbyService.sentMessages.last;
          expect(lastSentObject.deviceId, disconnectedDevice1.deviceId);
          expect(lastSentObject.data, sampleData1);
          Uint8List? receivedData1;
          connection1.receiveData.listen((d) => receivedData1 = d);
          mockScannerNearbyService.dataReceivedController.add({
            'deviceID': disconnectedDevice1.deviceId,
            'message': base64Encode(sampleData1),
          });
          fake.flushMicrotasks();
          expect(receivedData1, sampleData1);

          // Disconnect device 0
          mockScannerNearbyService.replaceDevice(
              disconnectedDevice0.deviceId, MockNearbyService.notConnected);
          fake.flushMicrotasks();
          expect(scannerNbService.connectedEndpoints.value.length, 1);

          // Device 1 disappears
          mockScannerNearbyService.removeDevice(disconnectedDevice1.deviceId);
          fake.flushMicrotasks();
          expect(scannerNbService.connectedEndpoints.value.length, 0);

          dispose();
        });
      });
    }),
  );
}
