// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/measure/nearby/measure_nb.dart';

void main() {
  late MeasureNb measureNearby;

  void init() {
    measureNearby = exampleMeasureNearby();
  }

  void dispose() {
    measureNearby.dispose();
  }

  group('MeasureNearby', () {
    // #########################################################################
    group('Advertizer', () {
      test('should be instantiated', () {
        init();
        expect(measureNearby, isNotNull);
        dispose();
      });
    });
  });
}
