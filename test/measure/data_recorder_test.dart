// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/com/shared/network_service.dart';
import 'package:mobile_network_evaluator/src/measure/data_recorder.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';
import 'package:mobile_network_evaluator/src/utils/utils.dart';

void main() {
  late DataRecorder advertizerDataRecorder;
  late DataRecorder scannerDataRecorder;
  late FakeService advertizerService;
  late FakeService scannerService;

  // ...........................................................................
  Future<void> init() async {
    advertizerService = FakeService.advertizer;
    scannerService = FakeService.scanner;
    advertizerService.start();
    scannerService.start();
    NetworkService.fakeConnect(scannerService, advertizerService);
    await flushMicroTasks();

    advertizerDataRecorder = exampleAdvertizerDataRecorder(
      connection: advertizerService.connections.value.first,
    );
    scannerDataRecorder = exampleScannerDataRecorder(
      connection: scannerService.connections.value.first,
    );

    await flushMicroTasks();
  }

  // ...........................................................................
  void dispose() {
    advertizerDataRecorder.dispose();
    scannerDataRecorder.dispose();
  }

  group('DataRecorder', () {
    // #########################################################################

    test('should send data packages as advertizer and acknowledge as scanner',
        () async {
      await init();

      scannerDataRecorder.record();
      await advertizerDataRecorder.record();

      expect(scannerDataRecorder.role, EndpointRole.scanner);

      const headerRow = 1;
      final rows = advertizerDataRecorder.resultCsv!.split('\n');

      const headerCol = 1;
      final cols = rows.first.split(',');

      expect(
          rows.length, advertizerDataRecorder.maxNumMeasurements + headerRow);
      expect(
          cols.length, advertizerDataRecorder.packageSizes.length + headerCol);

      dispose();
    });

    test('should complete code coverage', () {
      exampleAdvertizerDataRecorder();
      exampleScannerDataRecorder();
    });

    test('should allow to interrupt measurements with stop', () async {
      await init();

      DataRecorder.delayMeasurements = const Duration(seconds: 1);

      // Listen to measurement cycles and
      // stop after second measurement cycle
      advertizerDataRecorder.measurementCycles.listen(
        (event) {
          // Assume advertizer data recorder is running
          expect(advertizerDataRecorder.isRunning, true);

          // Stop the advertizer data recorder
          advertizerDataRecorder.stop();
        },
      );

      // Run the measurements
      scannerDataRecorder.record();
      await advertizerDataRecorder.record();

      // Expect it is stopped and no data have been written
      expect(advertizerDataRecorder.isRunning, false);
      expect(advertizerDataRecorder.resultCsv, null);

      DataRecorder.delayMeasurements = const Duration(milliseconds: 100);

      dispose();
    });

    test('should record on scanner side until stop is received', () async {
      await init();

      // Listen until recording was stopped
      bool isRecording = true;
      scannerDataRecorder.record().then(
            (_) => isRecording = false,
          );

      await flushMicroTasks();

      // Should still recording
      expect(isRecording, true);

      // Now let's stop the recording
      scannerDataRecorder.stop();
      await flushMicroTasks();

      // The record future should have completed
      expect(isRecording, false);

      dispose();
    });
  });
}
