// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/application.dart';
import 'package:mobile_network_evaluator/src/com/shared/network_service.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late Application appA;
  late Application appB;

  // ...........................................................................
  void init(FakeAsync fake) {
    appA = exampleApplication(name: 'appA');
    appB = exampleApplication(name: 'appB');
    fake.flushMicrotasks();
  }

  // ...........................................................................
  void dispose() {
    appA.dispose();
    appB.dispose();
  }

  // ...........................................................................
  void appBDiscoversAppA(FakeAsync fake) {
    NetworkService.fakeConnect(
      appA.remoteControlService.master,
      appB.remoteControlService.slave,
    );

    NetworkService.fakeConnect(
      appB.remoteControlService.master,
      appA.remoteControlService.slave,
    );

    appA.waitForConnections();
    appB.waitForConnections();

    fake.flushMicrotasks();
  }

  // ...........................................................................
  void connectBonjourMeasurement(FakeAsync fake) {
    NetworkService.fakeConnect(
      appA.measure!.networkService,
      appB.measure!.networkService,
    );
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

        // Initially AppA and AppB are in idle mode
        expect(appA.measurmentMode.value, MeasurementMode.idle);
        expect(appB.measurmentMode.value, MeasurementMode.idle);

        // Set AppA into TCP master mode.
        // AppB will be set into TCP slave mode.
        appA.role.value = EndpointRole.master;
        appA.measurmentMode.value = MeasurementMode.btle;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurementMode.btle);
        expect(appB.role.value, EndpointRole.slave);

        // AppB is in TCP slave mode.
        // Somebody sets the application to btle mode.
        // This will not change AppA, because a slave will not control master.
        expect(appB.role.value, EndpointRole.slave);
        expect(appB.measurmentMode.value, MeasurementMode.btle);
        appB.measurmentMode.value = MeasurementMode.btle;
        fake.flushMicrotasks();
        expect(appA.measurmentMode.value, MeasurementMode.btle);
        expect(appA.role.value, EndpointRole.master);

        // Now AppB is set to master mode.
        // Set applications into Nearby mode.
        // This will also change the other side because AppB is master now.
        expect(appA.role.value, EndpointRole.master);
        expect(appA.measurmentMode.value, MeasurementMode.btle);
        expect(appB.role.value, EndpointRole.slave);
        expect(appB.measurmentMode.value, MeasurementMode.btle);
        appB.role.value = EndpointRole.master;
        fake.flushMicrotasks();
        expect(appA.role.value, EndpointRole.slave);
        expect(appA.measurmentMode.value, MeasurementMode.btle);

        dispose();
      });
    });

    test('should allow to execute measurements', () {
      fakeAsync((fake) {
        init(fake);
        appBDiscoversAppA(fake);

        // Set applications into TCP mode
        appA.measurmentMode.value = MeasurementMode.btle;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurementMode.btle);

        // Start measurement
        appA.startMeasurements();
        fake.flushMicrotasks();

        // Download measurements
        // expect(appA.measurements, '...');

        dispose();
      });
    });

    test('should allow to stop an ongoing measurements', () {
      fakeAsync((fake) {
        init(fake);
        appBDiscoversAppA(fake);

        // Set applications into TCP mode
        appA.measurmentMode.value = MeasurementMode.btle;
        fake.flushMicrotasks();
        expect(appB.measurmentMode.value, MeasurementMode.btle);

        // At the beginning we are not measuring
        expect(appA.isMeasuring, false);
        expect(appB.isMeasuring, false);

        // Start measurement
        appA.startMeasurements();
        fake.flushMicrotasks();

        // Connect bonjour measurments
        connectBonjourMeasurement(fake);

        // Both sides will automatically measuring.
        // We cann now get the results
        fake.flushMicrotasks();
        expect(appA.measurementResults, isNotEmpty);

        // Now let's stop measuring
        appA.stopMeasurements();
        fake.flushMicrotasks();

        // Both sides should not measure anymore
        expect(appA.isMeasuring, false);
        expect(appB.isMeasuring, false);

        // Download measurements
        // expect(appA.measurements, '...');

        dispose();
      });
    });
  });
}
