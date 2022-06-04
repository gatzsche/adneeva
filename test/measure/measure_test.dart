// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adneeva/src/com/fake/fake_service.dart';
import 'package:adneeva/src/com/shared/network_service.dart';
import 'package:adneeva/src/measure/measure.dart';
import 'package:adneeva/src/measure/types.dart';

void main() {
  late Measure measureAdvertizer;
  late Measure measureScanner;
  late List<String> logs;

  // ...........................................................................
  Future<void> connectAdvertizerAndScanner() async {
    await NetworkService.fakeConnect<FakeServiceInfo>(
      measureScanner.networkService,
      measureAdvertizer.networkService,
    );
  }

  // ...........................................................................
  void init() {
    logs = [];
    void log(String m) {
      logs.add(m);
    }

    // Create a advertizer and a scanner instance
    measureAdvertizer = exampleMeasureAdvertizer(log: log);
    measureScanner = exampleMeasureScanner(log: log);
  }

  // ...........................................................................
  void dispose(FakeAsync fake) async {
    measureAdvertizer.disconnect();
    measureScanner.disconnect();
    measureAdvertizer.dispose();
    measureScanner.dispose();
    fake.flushMicrotasks();
  }

  group('Measure', () {
    // #########################################################################

    test(
        'should allow to measure data rate and latency '
        'when exchanging data between a advertizer and a scanner ', () {
      fakeAsync((fake) {
        init();
        // Start advertizer and scanner
        measureAdvertizer.connect();
        measureScanner.connect();
        connectAdvertizerAndScanner();
        fake.flushMicrotasks();

        // Perform measurements
        measureScanner.measure();
        measureAdvertizer.measure();
        fake.flushMicrotasks();

        // Stop advertizer and scanner
        measureAdvertizer.disconnect();
        expect(
            logs.last, MeasureLogMessages.disconnect(EndpointRole.advertizer));
        measureScanner.disconnect();
        expect(logs.last, MeasureLogMessages.disconnect(EndpointRole.scanner));

        // Get measurement results
        expect(measureAdvertizer.measurementResults.value, isNotEmpty);
        expect(measureScanner.measurementResults.value, isEmpty);

        dispose(fake);
      });
    });
  });
}
