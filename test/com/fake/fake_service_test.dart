// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/com/shared/connection.dart';
import 'package:mobile_network_evaluator/src/utils/utils.dart';

void main() {
  late FakeService masterFakeService;
  late FakeService slaveFakeService0;
  late FakeService slaveFakeService1;

  // ...........................................................................
  void init(FakeAsync fake) {
    masterFakeService = FakeService.master;
    slaveFakeService0 = FakeService.slave;
    slaveFakeService1 = FakeService.slave;
    fake.flushMicrotasks();
  }

  // ...........................................................................
  void dispose(FakeAsync fake) {
    masterFakeService.dispose();
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
          expect(masterFakeService.connections.value, isEmpty);
          expect(slaveFakeService0.connections.value, isEmpty);
          dispose(fake);
        });
      },
    );

    test('can be started and stopped', () {
      masterFakeService.start();
      masterFakeService.stop();

      slaveFakeService0.start();
      slaveFakeService0.stop();
    });

    test('can be connected to another fake services', () {
      fakeAsync((fake) {
        init(fake);

        // Connect a slave fake service to a master fake service
        slaveFakeService0.connectTo(masterFakeService);
        fake.flushMicrotasks();
        expect(masterFakeService.connections.value.length, 1);
        expect(slaveFakeService0.connections.value.length, 1);
        expect(slaveFakeService1.connections.value.length, 0);

        // Connect a slave fake service to a slave fake service
        slaveFakeService1.connectTo(masterFakeService);
        fake.flushMicrotasks();
        expect(masterFakeService.connections.value.length, 2);
        expect(slaveFakeService1.connections.value.length, 1);
        expect(slaveFakeService1.connections.value.length, 1);

        dispose(fake);
      });
    });

    test('can exchange data between endpoints', () {
      fakeAsync((fake) {
        init(fake);

        // Connect a slave fake service to a master fake service
        slaveFakeService0.connectTo(masterFakeService);
        slaveFakeService1.connectTo(masterFakeService);
        fake.flushMicrotasks();

        // Create a bunch of connections
        final masterSlave0 = masterFakeService.connections.value.first;

        final masterSlave1 = masterFakeService.connections.value.last;

        final slave0 = slaveFakeService0.connections.value.first;
        final slave1 = slaveFakeService1.connections.value.first;

        testSendingData(from: slave0, to: masterSlave0, fake: fake);
        testSendingData(from: slave1, to: masterSlave1, fake: fake);
        testSendingData(from: masterSlave0, to: slave0, fake: fake);
        testSendingData(from: masterSlave1, to: slave1, fake: fake);

        dispose(fake);
      });
    });
  });
}
