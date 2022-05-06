// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/measure/measure.dart';

void main() {
  late Measure measureMaster;
  late Measure measureSlave;
  late List<String> logs;

  void init(FakeAsync fake) {
    logs = [];
    void log(String m) {
      logs.add(m);
    }

    measureMaster = exampleMeasureMaster(log: log);
    measureSlave = exampleMeasureSlave(log: log);
    fake.flushMicrotasks();
  }

  void dispose(FakeAsync fake) {
    measureMaster.dispose();
    fake.flushMicrotasks();
  }

  group('Measure', () {
    // #########################################################################
    group('master', () {
      test('should start and stop master measuring ', () {
        fakeAsync((fake) {
          init(fake);
          measureMaster.start();
          expect(logs.last, MeasureLogMessages.startMeasurementAsMaster);
          measureMaster.stop();
          expect(logs.last, MeasureLogMessages.stopMeasurementAsMaster);
          dispose(fake);
        });
      });
    });

    group('slave', () {
      test('should start and stop master measuring ', () {
        fakeAsync((fake) {
          init(fake);
          measureSlave.start();
          expect(logs.last, MeasureLogMessages.startMeasurementAsSlave);
          measureSlave.stop();
          expect(logs.last, MeasureLogMessages.stopMeasurementAsSlave);
          dispose(fake);
        });
      });
    });
  });
}
