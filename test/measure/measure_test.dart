// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/measure/measure.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late Measure measureMaster;
  late Measure measureSlave;
  late List<String> logs;

  // ...........................................................................
  Future<void> connectMasterAndSlave() async {
    await (measureSlave.networkService as FakeService).connectTo(
      measureMaster.networkService as FakeService,
    );
  }

  // ...........................................................................
  void init() {
    logs = [];
    void log(String m) {
      logs.add(m);
    }

    // Create a master and a slave instance
    measureMaster = exampleMeasureMaster(log: log);
    measureSlave = exampleMeasureSlave(log: log);
  }

  // ...........................................................................
  void dispose(FakeAsync fake) async {
    measureMaster.stop();
    measureSlave.stop();
    measureMaster.dispose();
    measureSlave.dispose();
    fake.flushMicrotasks();
  }

  group('Measure', () {
    // #########################################################################

    test(
        'should allow to measure data rate and latency '
        'when exchanging data between a master and a slave ', () {
      fakeAsync((fake) {
        init();
        // Start master and slave
        measureMaster.start();
        measureSlave.start();
        connectMasterAndSlave();
        fake.flushMicrotasks();

        // Perform measurments
        measureSlave.measure();
        measureMaster.measure();
        fake.flushMicrotasks();

        // Stop master and slave
        measureMaster.stop();
        expect(logs.last, MeasureLogMessages.stop(MeasurmentRole.master));
        measureSlave.stop();
        expect(logs.last, MeasureLogMessages.stop(MeasurmentRole.slave));

        // Get measurment results
        expect(measureMaster.measurmentResults, isNotEmpty);
        expect(measureSlave.measurmentResults, isEmpty);

        dispose(fake);
      });
    });
  });
}
