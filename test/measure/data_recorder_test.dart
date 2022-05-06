// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/measure/data_recorder.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late DataRecorder masterDataRecorder;
  late DataRecorder slaveDataRecorder;
  late FakeService masterService;
  late FakeService slaveService;

  void init(FakeAsync fake) {
    masterService = FakeService.master;
    slaveService = FakeService.slave;
    slaveService.connectTo(masterService);
    fake.flushMicrotasks();

    masterDataRecorder = exampleMasterDataRecorder(
      connection: masterService.connections.value.first,
    );
    slaveDataRecorder = exampleSlaveDataRecorder(
      connection: slaveService.connections.value.first,
    );
  }

  void dispose(FakeAsync fake) {
    fake.flushMicrotasks();
  }

  group('DataRecorder', () {
    // #########################################################################

    test('should send data packages as master and acknowledge as slave', () {
      fakeAsync((fake) {
        init(fake);

        slaveDataRecorder.run();
        fake.flushMicrotasks();
        masterDataRecorder.run();
        fake.flushMicrotasks();

        expect(slaveDataRecorder.role, MeasurmentRole.slave);

        dispose(fake);
      });
    });
  });
}
