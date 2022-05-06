// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/measure/data_recorder.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';
import 'package:mobile_network_evaluator/src/utils/utils.dart';

void main() {
  late DataRecorder masterDataRecorder;
  late DataRecorder slaveDataRecorder;
  late FakeService masterService;
  late FakeService slaveService;

  Future<void> init() async {
    masterService = FakeService.master;
    slaveService = FakeService.slave;
    slaveService.connectTo(masterService);
    await flushMicroTasks();

    masterDataRecorder = exampleMasterDataRecorder(
      connection: masterService.connections.value.first,
    );
    slaveDataRecorder = exampleSlaveDataRecorder(
      connection: slaveService.connections.value.first,
    );
  }

  void dispose() {
    masterDataRecorder.dispose();
    slaveDataRecorder.dispose();
  }

  group('DataRecorder', () {
    // #########################################################################

    test('should send data packages as master and acknowledge as slave',
        () async {
      await init();

      slaveDataRecorder.run();
      await masterDataRecorder.run();

      expect(slaveDataRecorder.role, MeasurmentRole.slave);

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
  });
}
