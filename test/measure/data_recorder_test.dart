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
  late DataRecorder masterDataRecorder;
  late DataRecorder slaveDataRecorder;
  late FakeService masterService;
  late FakeService slaveService;

  // ...........................................................................
  Future<void> init() async {
    masterService = FakeService.master;
    slaveService = FakeService.slave;
    masterService.start();
    slaveService.start();
    NetworkService.fakeConnect(slaveService, masterService);
    await flushMicroTasks();

    masterDataRecorder = exampleMasterDataRecorder(
      connection: masterService.connections.value.first,
    );
    slaveDataRecorder = exampleSlaveDataRecorder(
      connection: slaveService.connections.value.first,
    );

    await flushMicroTasks();
  }

  // ...........................................................................
  void dispose() {
    masterDataRecorder.dispose();
    slaveDataRecorder.dispose();
  }

  group('DataRecorder', () {
    // #########################################################################

    test('should send data packages as master and acknowledge as slave',
        () async {
      await init();

      slaveDataRecorder.record();
      await masterDataRecorder.record();

      expect(slaveDataRecorder.role, EndpointRole.slave);

      const headerRow = 1;
      final rows = masterDataRecorder.resultCsv!.split('\n');

      const headerCol = 1;
      final cols = rows.first.split(',');

      expect(rows.length, masterDataRecorder.maxNumMeasurements + headerRow);
      expect(cols.length, masterDataRecorder.packageSizes.length + headerCol);

      dispose();
    });

    test('should complete code coverage', () {
      exampleMasterDataRecorder();
      exampleSlaveDataRecorder();
    });

    test('should allow to interrupt measurements with stop', () async {
      await init();

      DataRecorder.delayMeasurements = true;

      // Listen to measurement cycles and
      // stop after second measurement cycle
      masterDataRecorder.measurementCycles.listen(
        (event) {
          // Assume master data recorder is running
          expect(masterDataRecorder.isRunning, true);

          // Stop the master data recorder
          masterDataRecorder.stop();
        },
      );

      // Run the measurements
      slaveDataRecorder.record();
      await masterDataRecorder.record();

      // Expect it is stopped and no data have been written
      expect(masterDataRecorder.isRunning, false);
      expect(masterDataRecorder.resultCsv, null);

      DataRecorder.delayMeasurements = false;

      dispose();
    });

    test('should record on slave side until stop is received', () async {
      await init();

      // Listen until recording was stopped
      bool isRecording = true;
      slaveDataRecorder.record().then(
            (_) => isRecording = false,
          );

      await flushMicroTasks();

      // Should still recording
      expect(isRecording, true);

      // Now let's stop the recording
      slaveDataRecorder.stop();
      await flushMicroTasks();

      // The record future should have completed
      expect(isRecording, false);

      dispose();
    });
  });
}
