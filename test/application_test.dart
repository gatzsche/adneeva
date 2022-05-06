// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/application.dart';
import 'package:mobile_network_evaluator/src/com/tcp/mocks/mock_bonsoir_discovery.dart';
import 'package:mobile_network_evaluator/src/com/tcp/mocks/mock_server_socket.dart';
import 'package:mobile_network_evaluator/src/com/tcp/mocks/mock_socket.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late Application appA;
  late Application appB;

  late MockBonsoirDiscovery appBDiscovery;

  // ...........................................................................
  void init(FakeAsync fake) {
    appA = exampleApplication();
    appB = exampleApplication();
    fake.flushMicrotasks();

    appBDiscovery =
        appB.remoteControlService.bonsoirDiscovery as MockBonsoirDiscovery;

    fake.flushMicrotasks();
  }

  // ...........................................................................
  void dispose() {
    appA.dispose();
    appB.dispose();
  }

  // ...........................................................................
  void appBDiscoversAppA(FakeAsync fake) {
    appBDiscovery.mockDiscovery(ip: appA.ip, port: appA.port);
    fake.flushMicrotasks();

    final appBSocket = appB
        .remoteControlService.connections.value.first.receiveData as MockSocket;
    final appASocket =
        appA.remoteControlService.serverSocket as MockServerSocket;

    appASocket.connectedSocketsIn.add(appBSocket);
    fake.flushMicrotasks();
  }

  group('AppA, AppB', () {
    // #########################################################################

    test('should allow to wait until connected', () {
      fakeAsync((fake) {
        init(fake);

        bool finishedWaitingAppA = false;
        appA.waitUntilConnected.then(
          (_) => finishedWaitingAppA = true,
        );
        bool finishedWaitingAppB = false;
        appB.waitUntilConnected.then(
          (_) => finishedWaitingAppB = true,
        );

        // Initially there is no connection between appA and appB
        expect(appA.isConnected, isFalse);
        expect(appB.isConnected, isFalse);
        expect(finishedWaitingAppA, isFalse);
        expect(finishedWaitingAppB, isFalse);

        // Let appA discover appB
        appBDiscoversAppA(fake);

        // Connected should be true
        expect(appA.isConnected, isTrue);
        expect(appB.isConnected, isTrue);

        // Waiting should be over
        expect(finishedWaitingAppA, isTrue);
        expect(finishedWaitingAppB, isTrue);

        dispose();
      });
    });

    test('should turn each other into tpc, nearby or btle mode ', () {
      fakeAsync((fake) {
        init(fake);
        appBDiscoversAppA(fake);

        // Set applications into TCP mode
        appA.measurmentMode.value = MeasurmentMode.tcp;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurmentMode.tcp);

        // Set applications into Nearby mode
        appA.measurmentMode.value = MeasurmentMode.nearby;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurmentMode.nearby);

        // Set applications into BTLE mode
        appA.measurmentMode.value = MeasurmentMode.btle;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurmentMode.btle);

        // Set applications into TCP mode
        appB.measurmentMode.value = MeasurmentMode.tcp;
        fake.flushMicrotasks();
        expect(appA.measurmentMode.value, MeasurmentMode.tcp);

        dispose();
      });
    });

    test('should allow to execute measurments', () {
      fakeAsync((fake) {
        init(fake);
        appBDiscoversAppA(fake);

        // Set applications into TCP mode
        appA.measurmentMode.value = MeasurmentMode.tcp;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurmentMode.tcp);

        // Start measurement
        appA.startMeasurements();
        fake.flushMicrotasks();

        // Download measurments
        // expect(appA.measurements, '...');

        dispose();
      });
    });

    test('should allow to stop an ongoing measurments', () {
      fakeAsync((fake) {
        init(fake);
        appBDiscoversAppA(fake);

        // Set applications into TCP mode
        appA.measurmentMode.value = MeasurmentMode.tcp;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurmentMode.tcp);

        // Start measurement
        appA.startMeasurements();
        fake.flushMicrotasks();
        appA.stopMeasurments();

        // Download measurments
        // expect(appA.measurements, '...');

        dispose();
      });
    });
  });
}
