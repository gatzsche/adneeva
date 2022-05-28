// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/com/shared/connection.dart';
import 'package:mobile_network_evaluator/src/com/shared/network_service.dart';
import 'package:mobile_network_evaluator/src/utils/utils.dart';

void main() {
  late FakeService advertizerFakeService;
  late FakeService scannerFakeService0;
  late FakeService scannerFakeService1;

  // ...........................................................................
  void init(FakeAsync fake) {
    advertizerFakeService = FakeService.advertizer;
    scannerFakeService0 = FakeService.scanner;
    scannerFakeService1 = FakeService.scanner;
    fake.flushMicrotasks();
  }

  // ...........................................................................
  void dispose(FakeAsync fake) {
    advertizerFakeService.dispose();
    fake.flushMicrotasks();
  }

  void testSendingData({
    required Connection from,
    required Connection to,
    required FakeAsync fake,
  }) {
    // Listen to received data
    String? receivedData;
    final s = to.receiveData.listen(
      (data) => receivedData = data.string,
    );

    // Send data
    const sendData = 'Hello World';
    from.sendData(sendData.uint8List);
    fake.flushMicrotasks();
    fake.flushTimers();

    expect(sendData, receivedData);

    s.cancel();
  }

  group('FakeService', () {
    // #########################################################################

    test(
      'should have right default values',
      () {
        fakeAsync((fake) {
          init(fake);
          expect(advertizerFakeService.connections.value, isEmpty);
          expect(scannerFakeService0.connections.value, isEmpty);
          dispose(fake);
        });
      },
    );

    test('can be started and stopped', () {
      advertizerFakeService.start();
      advertizerFakeService.stop();

      scannerFakeService0.start();
      scannerFakeService0.stop();
    });

    test('can be connected to another fake services', () {
      fakeAsync((fake) {
        init(fake);

        advertizerFakeService.start();
        scannerFakeService0.start();

        expect(advertizerFakeService.isConnected, false);
        expect(scannerFakeService0.isConnected, false);
        expect(scannerFakeService1.isConnected, false);

        // Connect a scanner fake service to a advertizer fake service
        NetworkService.fakeConnect(scannerFakeService0, advertizerFakeService);
        fake.flushMicrotasks();
        expect(advertizerFakeService.connections.value.length, 1);
        expect(scannerFakeService0.connections.value.length, 1);
        expect(scannerFakeService1.connections.value.length, 0);
        expect(advertizerFakeService.isConnected, true);
        expect(scannerFakeService0.isConnected, true);
        expect(scannerFakeService1.isConnected, false);

        // Connect a scanner fake service to a scanner fake service
        scannerFakeService1.start();
        NetworkService.fakeConnect(scannerFakeService1, advertizerFakeService);
        fake.flushMicrotasks();
        expect(advertizerFakeService.connections.value.length, 2);
        expect(scannerFakeService1.connections.value.length, 1);
        expect(scannerFakeService1.connections.value.length, 1);
        expect(scannerFakeService0.isConnected, true);
        expect(scannerFakeService1.isConnected, true);

        scannerFakeService0.stop();
        advertizerFakeService.stop();

        dispose(fake);
      });
    });

    test('allows to wait for first connections', () {
      fakeAsync((fake) {
        init(fake);

        // Listen to firstConnection
        Connection? firstScannerConnection;
        Connection? firstAdvertizerConnection;
        scannerFakeService0.firstConnection.then(
          (c) => firstScannerConnection = c,
        );

        advertizerFakeService.firstConnection.then(
          (value) => firstAdvertizerConnection = value,
        );

        // Initially it is still waiting
        fake.flushMicrotasks();

        expect(firstScannerConnection, isNull);
        expect(firstAdvertizerConnection, isNull);

        // Now let's connect
        scannerFakeService0.start();
        advertizerFakeService.start();

        NetworkService.fakeConnect(scannerFakeService0, advertizerFakeService);
        fake.flushMicrotasks();

        expect(firstAdvertizerConnection, isNotNull);
        expect(firstScannerConnection, isNotNull);

        // Lets listen to first connection again
        Connection? firstScannerConnection2;
        scannerFakeService0.firstConnection.then(
          (c) => firstScannerConnection2 = c,
        );
        fake.flushMicrotasks();
        expect(firstScannerConnection2, isNotNull);

        dispose(fake);
      });
    });

    test('can exchange data between endpoints', () {
      fakeAsync((fake) {
        init(fake);

        // Connect a scanner fake service to a advertizer fake service
        scannerFakeService0.start();
        scannerFakeService1.start();
        advertizerFakeService.start();

        NetworkService.fakeConnect(scannerFakeService0, advertizerFakeService);
        NetworkService.fakeConnect(scannerFakeService1, advertizerFakeService);
        fake.flushMicrotasks();

        // Create a bunch of connections
        final advertizerScanner0 =
            advertizerFakeService.connections.value.first;

        final advertizerScanner1 = advertizerFakeService.connections.value.last;

        final scanner0 = scannerFakeService0.connections.value.first;
        final scanner1 = scannerFakeService1.connections.value.first;

        testSendingData(from: scanner0, to: advertizerScanner0, fake: fake);
        testSendingData(from: scanner1, to: advertizerScanner1, fake: fake);
        testSendingData(from: advertizerScanner0, to: scanner0, fake: fake);
        testSendingData(from: advertizerScanner1, to: scanner1, fake: fake);

        dispose(fake);
      });
    });
  });
}
