// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/shared/network_service.dart';
import 'package:mobile_network_evaluator/src/measure/measure.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late Measure measureMaster;
  late Measure measureSlave;
  late List<String> logs;

  // ...........................................................................
  Future<void> connectMasterAndSlave() async {
    await NetworkService.fakeConnect(
      measureSlave.networkService,
      measureMaster.networkService,
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
    measureMaster.disconnect();
    measureSlave.disconnect();
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
        measureMaster.connect();
        measureSlave.connect();
        connectMasterAndSlave();
        fake.flushMicrotasks();

        // Perform measurements
        measureSlave.measure();
        measureMaster.measure();
        fake.flushMicrotasks();

        // Stop master and slave
        measureMaster.disconnect();
        expect(logs.last, MeasureLogMessages.stop(EndpointRole.master));
        measureSlave.disconnect();
        expect(logs.last, MeasureLogMessages.stop(EndpointRole.slave));

        // Get measurement results
        expect(measureMaster.measurementResults.value, isNotEmpty);
        expect(measureSlave.measurementResults.value, isEmpty);

        dispose(fake);
      });
    });
  });
}
