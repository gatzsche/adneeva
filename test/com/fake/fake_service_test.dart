// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';

void main() {
  late FakeService masterFackeService;
  late FakeService slaveFakeService;

  void init() {
    masterFackeService = exampleMasterFakeService();
    slaveFakeService = exampleSlaveFakeService();
  }

  void dispose() {
    masterFackeService.dispose();
  }

  group('FakeService', () {
    // #########################################################################

    test('should have right default values', () {
      init();
      expect(masterFackeService.connections.value, isEmpty);
      expect(slaveFakeService.connections.value, isEmpty);
      dispose();
    });
  });
}
