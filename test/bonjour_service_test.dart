// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/bonjour_service/mocks/mock_bonsoir_discovery.dart';
import 'package:mobile_network_evaluator/bonjour_service/mocks/mock_bonjour_service.dart';
import 'package:mobile_network_evaluator/bonjour_service/mocks/mock_server_socket.dart';
import 'package:mobile_network_evaluator/bonjour_service/mocks/mock_socket.dart';
import 'package:mobile_network_evaluator/network_service.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late MockBonjourService master;
  late MockBonjourService slave;
  late MockBonsoirDiscovery bonsoirDiscovery;

  // ...........................................................................
  void mockDiscovery(
      {BonsoirDiscoveryEventType? type, bool noIpAddress = false}) {
    final description = master.serviceDescription;

    bonsoirDiscovery.eventStreamIn.add(
      BonsoirDiscoveryEvent(
        type: type ?? BonsoirDiscoveryEventType.DISCOVERY_SERVICE_RESOLVED,
        service: ResolvedBonsoirService(
          ip: noIpAddress ? null : description.ipAddress,
          name: description.name,
          port: description.port,
          type: description.serviceId,
        ),
      ),
    );
  }

  // ...........................................................................
  void mockBroadcastWithoutIp() => mockDiscovery(noIpAddress: true);

  // ...........................................................................
  void mockDiscoveryLost() =>
      mockDiscovery(type: BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST);

  // ...........................................................................
  List<MockSocket> connectedClientSockets() => (slave.connections
      .map(
        (e) => e.receiveData as MockSocket,
      )
      .toList());

  // ...........................................................................
  MockServerSocket? serverSocket() =>
      master.test('serverSocket') as MockServerSocket?;

  // ...........................................................................
  void mockSlaveConnectsToMaster() {
    final clntSockets = connectedClientSockets();
    final srvSocket = serverSocket();

    expect(clntSockets.length, 1);
    expect(srvSocket, isNotNull);
    final clientSocket = clntSockets.first;
    srvSocket!.connectedSocketsIn.add(clientSocket);
  }

  // ...........................................................................
  void initMocks() {
    master = MockBonjourService(mode: NetworkServiceMode.master);
    slave = MockBonjourService(mode: NetworkServiceMode.slave);
    bonsoirDiscovery = slave.test('bonsoirDiscovery') as MockBonsoirDiscovery;
  }

  // ...........................................................................
  void startMasterAndSlave(FakeAsync fake) {
    master.start();
    slave.start();
    mockDiscovery();
    fake.flushMicrotasks();
    mockSlaveConnectsToMaster();
    fake.flushMicrotasks();
  }

  // ...........................................................................
  void stopMasterAndSlave(FakeAsync fake) {
    master.stop();
    slave.stop();
    fake.flushMicrotasks();
  }

  group('BonjourService', () {
    void init() {
      initMocks();
    }

    void dispose() {
      master.dispose();
      slave.dispose();
    }

    test('should initialize correctly', () {
      fakeAsync((fake) {
        init();

        // ......................................
        // Initializes master and slave correctly
        expect(master, isNotNull);
        expect(slave, isNotNull);
        fake.flushMicrotasks();

        // ...........
        // Start slave
        // => Slave should scan for the service
        slave.start();
        fake.flushMicrotasks();

        // No connections are available at the beginning
        expect(connectedClientSockets(), isEmpty);
        expect(slave.connections, isEmpty);
        expect(master.connections, isEmpty);

        // ............
        // Start master

        // At the beginning we don't have a server socket listening for
        // incoming connections
        expect(serverSocket(), isNull);

        // Let's start the master.
        master.start();
        fake.flushMicrotasks();

        // This means that the master creates a tcp server that listens to
        // incoming connections.
        expect(serverSocket(), isNotNull);

        stopMasterAndSlave(fake);

        dispose();
      });
    });

    test('should discover and connect services correctly', () {
      fakeAsync((fake) {
        init();

        // ......................................
        // Slave discovers and connects a service
        master.start();
        slave.start();

        // Slave should discover the service broadcasted by the server
        mockDiscovery();
        fake.flushMicrotasks();

        // Slave should connect to the server and create a connection
        expect(slave.connections.length, 1);
        mockSlaveConnectsToMaster();
        fake.flushMicrotasks();

        // Master should accept the connection and create a connection
        // object also
        expect(master.connections.length, 1);

        stopMasterAndSlave(fake);

        dispose();
      });
    });

    test('should exchange data betwen master and slave correctly', () {
      fakeAsync((fake) {
        init();

        // The connection object can be used to send data from slave to master
        startMasterAndSlave(fake);

        final masterConnection = master.connections.first;
        final slaveConnection = slave.connections.first;

        final dataIn1 = Uint8List.fromList([1, 2, 3]);
        final dataIn2 = Uint8List.fromList([4, 5, 6]);

        Uint8List? dataReceivedAtMaster;
        Uint8List? dataReceivedAtSlave;
        masterConnection.receiveData.listen(
          (data) => dataReceivedAtMaster = data,
        );
        slaveConnection.receiveData.listen(
          (data) => dataReceivedAtSlave = data,
        );

        // Send data from master to slave
        masterConnection.sendData(dataIn1);
        fake.flushMicrotasks();
        expect(dataReceivedAtSlave, dataIn1);

        // Send data from slave to master
        slaveConnection.sendData(dataIn2);
        fake.flushMicrotasks();
        expect(dataReceivedAtMaster, dataIn2);

        // ......................
        // Stop master and client
        stopMasterAndSlave(fake);

        fake.flushMicrotasks();
      });
    });

    test('should behave correctly when service gets lost', () {
      fakeAsync((fake) {
        init();

        startMasterAndSlave(fake);

        // .................
        // Service gets lost

        // The connection object can be used to send data from slave to master

        // We do not react to lost services yet.
        // This needs to be added later
        mockDiscoveryLost();
        fake.flushMicrotasks();

        // Broadcasting a service without an IP should create an error.
        mockBroadcastWithoutIp();
        fake.flushMicrotasks();
        expect(slave.loggedData.last,
            'Service with name "Example Bonjour Service" has no IP address');

        // ......................
        // Stop master and client
        stopMasterAndSlave(fake);

        fake.flushMicrotasks();
      });
    });

    test('should behave correctly when slave disconnects', () {
      fakeAsync((fake) {
        init();

        startMasterAndSlave(fake);
        expect(slave.connections.length, 1);
        expect(master.connections.length, 1);

        // ..............................
        // Slave disconnects a connection

        slave.connections.first.disconnect();
        fake.flushMicrotasks();

        // The connection should be removed from the array of connections
        expect(slave.connections, isEmpty);

        // Also on master the connection should be disconnected
        expect(master.connections, isEmpty);

        // ......................
        // Stop master and client
        stopMasterAndSlave(fake);
      });
    });

    test('should behave correctly when master disconnects', () {
      fakeAsync((fake) {
        init();

        startMasterAndSlave(fake);
        expect(slave.connections.length, 1);
        expect(master.connections.length, 1);

        // ...............................
        // Master disconnects a connection
        master.connections.first.disconnect();
        fake.flushMicrotasks();

        // On both sides: The connection should be removed
        expect(slave.connections, isEmpty);
        expect(master.connections, isEmpty);

        // ......................
        // Stop master and client
        stopMasterAndSlave(fake);
      });
    });

    test('should successfully survive multiple start and stops', () {
      fakeAsync((fake) {
        init();

        // .....
        // Start
        startMasterAndSlave(fake);
        expect(slave.connections.length, 1);
        expect(master.connections.length, 1);

        // ....
        // Stop
        stopMasterAndSlave(fake);
        expect(slave.connections.length, 0);
        expect(master.connections.length, 0);

        // .....
        // Start
        startMasterAndSlave(fake);
        expect(slave.connections.length, 1);
        expect(master.connections.length, 1);

        // ....
        // Stop
        stopMasterAndSlave(fake);
        expect(slave.connections.length, 0);
        expect(master.connections.length, 0);
      });
    });
  });
}
