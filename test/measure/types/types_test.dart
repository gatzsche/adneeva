// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:adneeva/src/measure/types.dart';

void main() {
  group('EndpointRole', () {
    test('.string should return the role as string', () {
      expect(EndpointRole.advertizer.string, 'advertizer');
      expect(EndpointRole.scanner.string, 'scanner');
    });
  });

  group('EndpointRole', () {
    test('.string should return the mode as string', () {
      expect(MeasurementMode.btle.string, 'btle');
    });
  });
}
