// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adneeva/src/com/tcp/mocks/mock_bonjour_service.dart';
import 'package:adneeva/src/com/tcp/mocks/mock_bonsoir_broadcast.dart';
import 'package:adneeva/src/com/tcp/mocks/mock_bonsoir_discovery.dart';
import 'package:adneeva/src/com/tcp/mocks/mock_server_socket.dart';
import 'package:adneeva/src/com/tcp/mocks/mock_socket.dart';
import 'package:adneeva/src/measure/types.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late MockBonjourService advertizer;
  late MockBonjourService scanner;
  late MockBonsoirDiscovery bonsoirDiscovery;
  late MockBonsoirBroadcast bonsoirBroadcast;

  // ...........................................................................
  void mockDiscovery({
    BonsoirDiscoveryEventType? eventType,
    bool noIpAddress = false,
    String ip = '123.456.789.123',
  }) {
    final description = advertizer.service;

    bonsoirDiscovery.mockDiscovery(
      eventType: eventType,
      service: ResolvedBonsoirService(
        ip: noIpAddress ? null : ip,
        name: description.name,
        port: description.port,
        type: description.type,
      ),
    );
  }

  // ...........................................................................
  void mockDiscoverOwnService() => mockDiscovery(ip: '127.0.0.1');

  // ...........................................................................
  void mockDiscoverServicesWithoutIp() => mockDiscovery(noIpAddress: true);

  // ...........................................................................
  void mockDiscoveryLost() => mockDiscovery(
      eventType: BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST);

  // ...........................................................................
  List<MockSocket> connectedClientSockets() => (scanner.connectedEndpoints.value
      .map(
        (e) => e.receiveData as MockSocket,
      )
      .toList());

  // ...........................................................................
  MockServerSocket? serverSocket() =>
      advertizer.serverSocket as MockServerSocket?;

  // ...........................................................................
  void mockScannerConnectsToAdvertizer() {
    final clntSockets = connectedClientSockets();
    final srvSocket = serverSocket();

    expect(clntSockets.length, 1);
    expect(srvSocket, isNotNull);
    final clientSocket = clntSockets.first;
    srvSocket!.connectedSocketsIn.add(clientSocket.otherEndpoint);
  }

  // ...........................................................................
  void initMocks() {
    advertizer = MockBonjourService(role: EndpointRole.advertizer);
    scanner = MockBonjourService(role: EndpointRole.scanner);
    bonsoirDiscovery = scanner.bonsoirDiscovery as MockBonsoirDiscovery;
    bonsoirBroadcast = advertizer.bonsoirBroadcast as MockBonsoirBroadcast;
  }

  // ...........................................................................
  void startAdvertizerAndScanner(FakeAsync fake) {
    advertizer.start();
    scanner.start();
    fake.flushMicrotasks();
    mockDiscovery();
    fake.flushMicrotasks();
    mockScannerConnectsToAdvertizer();
    fake.flushMicrotasks();
  }

  // ...........................................................................
  void stopAdvertizerAndScanner(FakeAsync fake) {
    advertizer.stop();
    scanner.stop();
    fake.flushMicrotasks();
  }

  group('BonjourService', () {
    void init() {
      initMocks();
    }

    void dispose() {
      advertizer.dispose();
      scanner.dispose();
    }

    test('should initialize correctly', () {
      fakeAsync((fake) {
        init();

        expect(bonsoirBroadcast, isNotNull);
        expect(bonsoirDiscovery, isNotNull);

        // ......................................
        // Initializes advertizer and scanner correctly
        expect(advertizer, isNotNull);
        expect(scanner, isNotNull);
        fake.flushMicrotasks();

        // ...........
        // Start scanner
        // => Scanner should scan for the service
        scanner.start();
        fake.flushMicrotasks();

        // No connections are available at the beginning
        expect(connectedClientSockets(), isEmpty);
        expect(scanner.connectedEndpoints.value, isEmpty);
        expect(advertizer.connectedEndpoints.value, isEmpty);

        // ............
        // Start advertizer

        // At the beginning we don't have a server socket listening for
        // incoming connections
        expect(serverSocket(), isNull);

        // Let's start the advertizer.
        advertizer.start();
        fake.flushMicrotasks();

        // This means that the advertizer creates a tcp server that listens to
        // incoming connections.
        expect(serverSocket(), isNotNull);

        stopAdvertizerAndScanner(fake);

        dispose();
      });
    });

    test('should discover and connect services correctly', () {
      fakeAsync((fake) {
        init();

        // ......................................
        // Scanner discovers and connects a service
        advertizer.start();
        scanner.start();
        fake.flushMicrotasks();

        // Scanner should discover the service broadcasted by the server
        mockDiscovery();
        fake.flushMicrotasks();

        // Scanner should connect to the server and create a connection
        expect(scanner.connectedEndpoints.value.length, 1);
        mockScannerConnectsToAdvertizer();
        fake.flushMicrotasks();

        // Advertizer should accept the connection and create a connection
        // object also
        expect(advertizer.connectedEndpoints.value.length, 1);

        stopAdvertizerAndScanner(fake);

        dispose();
      });
    });

    test('should not discover own service', () {
      fakeAsync((fake) {
        init();

        // Scanner discovers and connects a service
        advertizer.start();
        scanner.start();

        // Scanner should discover the service broadcasted by the server
        mockDiscoverOwnService();
        fake.flushMicrotasks();

        // There should not be a discovery of the own service
        expect(scanner.connectedEndpoints.value.length, 0);
        expect(advertizer.connectedEndpoints.value.length, 0);

        stopAdvertizerAndScanner(fake);
        dispose();
      });
    });

    test('should exchange data betwen advertizer and scanner correctly', () {
      fakeAsync((fake) {
        init();

        // The connection object can be used to send data from scanner to advertizer
        startAdvertizerAndScanner(fake);

        final advertizerConnection = advertizer.connectedEndpoints.value.first;
        final scannerConnection = scanner.connectedEndpoints.value.first;

        final dataIn1 = Uint8List.fromList([1, 2, 3]);
        final dataIn2 = Uint8List.fromList([4, 5, 6]);

        Uint8List? dataReceivedAtAdvertizer;
        Uint8List? dataReceivedAtScanner;
        advertizerConnection.receiveData.listen(
          (data) => dataReceivedAtAdvertizer = data,
        );
        scannerConnection.receiveData.listen(
          (data) => dataReceivedAtScanner = data,
        );

        // Send data from advertizer to scanner
        advertizerConnection.sendData(dataIn1);
        fake.flushMicrotasks();
        expect(dataReceivedAtScanner, dataIn1);

        // Send data from scanner to advertizer
        scannerConnection.sendData(dataIn2);
        fake.flushMicrotasks();
        expect(dataReceivedAtAdvertizer, dataIn2);

        // Make some additional checks
        expect(
          advertizer.endpointForService(advertizerConnection.serviceInfo),
          advertizerConnection,
        );

        // ......................
        // Stop advertizer and client
        stopAdvertizerAndScanner(fake);

        fake.flushMicrotasks();
      });
    });

    test('should behave correctly when service gets lost', () {
      fakeAsync((fake) {
        init();

        startAdvertizerAndScanner(fake);

        // .................
        // Service gets lost

        // The connection object can be used to send data from scanner to advertizer

        // We do not react to lost services yet.
        // This needs to be added later
        mockDiscoveryLost();
        fake.flushMicrotasks();

        // Broadcasting a service without an IP should create an error.
        mockDiscoverServicesWithoutIp();
        fake.flushMicrotasks();
        expect(scanner.loggedData.last,
            'Service with name "Example Bonjour Service" has no IP address');

        // ......................
        // Stop advertizer and client
        stopAdvertizerAndScanner(fake);

        fake.flushMicrotasks();
      });
    });

    test('should behave correctly when scanner disconnects', () {
      fakeAsync((fake) {
        init();

        startAdvertizerAndScanner(fake);
        expect(scanner.connectedEndpoints.value.length, 1);
        expect(advertizer.connectedEndpoints.value.length, 1);

        // ..............................
        // Scanner disconnects a connection

        scanner.connectedEndpoints.value.first.disconnect();
        fake.flushMicrotasks();

        // The connection should be removed from the array of connections
        expect(scanner.connectedEndpoints.value, isEmpty);

        // Also on advertizer the connection should be disconnected
        expect(advertizer.connectedEndpoints.value, isEmpty);

        // ......................
        // Stop advertizer and client
        stopAdvertizerAndScanner(fake);
      });
    });

    test('should behave correctly when advertizer disconnects', () {
      fakeAsync((fake) {
        init();

        startAdvertizerAndScanner(fake);
        expect(scanner.connectedEndpoints.value.length, 1);
        expect(advertizer.connectedEndpoints.value.length, 1);

        // ...............................
        // Advertizer disconnects a connection
        advertizer.connectedEndpoints.value.first.disconnect();
        fake.flushMicrotasks();

        // On both sides: The connection should be removed
        expect(scanner.connectedEndpoints.value, isEmpty);
        expect(advertizer.connectedEndpoints.value, isEmpty);

        // ......................
        // Stop advertizer and client
        stopAdvertizerAndScanner(fake);
      });
    });

    test('should successfully survive multiple start and stops', () {
      fakeAsync((fake) {
        init();

        // .....
        // Start
        startAdvertizerAndScanner(fake);
        expect(scanner.connectedEndpoints.value.length, 1);
        expect(advertizer.connectedEndpoints.value.length, 1);

        // ....
        // Stop
        stopAdvertizerAndScanner(fake);
        expect(scanner.connectedEndpoints.value.length, 0);
        expect(advertizer.connectedEndpoints.value.length, 0);

        // .....
        // Start
        startAdvertizerAndScanner(fake);
        expect(scanner.connectedEndpoints.value.length, 1);
        expect(advertizer.connectedEndpoints.value.length, 1);

        // ....
        // Stop
        stopAdvertizerAndScanner(fake);
        expect(scanner.connectedEndpoints.value.length, 0);
        expect(advertizer.connectedEndpoints.value.length, 0);
      });
    });

    test('should behave correctly, when discovered port cannot be connected',
        () async {
      fakeAsync((fake) {
        // Setup socket to throw a socket exception next time
        MockSocket.failAtNextConnect = true;

        // Start a scanner service
        init();
        scanner.start();
        fake.flushMicrotasks();

        // Mock discovery of a bonjour service
        mockDiscovery();
        fake.flushMicrotasks();

        // Connection should have failed.
        expect(scanner.connectedEndpoints.value.length, 0);
        expect(scanner.loggedData.last,
            'SocketException: Connection refused, port = 12457');
      });
    });
  });
}
