// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/measure/tcp/measure_tcp.dart';

void main() {
  late MeasureTcp measureTcp;

  void init() {
    measureTcp = exampleMeasureTcp();
  }

  void dispose() {
    measureTcp.dispose();
  }

  group('MeasureTcp', () {
    // #########################################################################
    group('Constructor', () {
      test('should be instantiated', () {
        init();
        expect(measureTcp, isNotNull);
        dispose();
      });
    });
  });
}
