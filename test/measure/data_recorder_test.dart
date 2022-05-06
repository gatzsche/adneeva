// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/measure/data_recorder.dart';

void main() {
  late DataRecorder dataRecorder;

  void init() {
    dataRecorder = exampleMasterDataRecorder();
  }

  void dispose() {
    dataRecorder.dispose();
  }

  group('DataRecorder', () {
    // #########################################################################
    group('Constructor', () {
      test('should be instantiated', () {
        init();
        expect(dataRecorder, isNotNull);
        dispose();
      });
    });
  });
}
