// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/measure/measure.dart';

void main() {
  late Measure measure;

  void init() {
    measure = exampleMeasure();
  }

  void dispose() {
    measure.dispose();
  }

  group('Measure', () {
    // #########################################################################
    group('Constructor', () {
      test('should be instantiated', () {
        init();
        expect(measure, isNotNull);
        measure.start();
        measure.stop();
        dispose();
      });
    });
  });
}
