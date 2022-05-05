// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/application.dart';

void main() {
  late Application application;

  void init() {
    application = exampleApplication();
  }

  void dispose() {
    application.dispose();
  }

  group('Application', () {
    // #########################################################################
    group('Constructor', () {
      test('should be instantiated', () {
        init();
        expect(application, isNotNull);
        dispose();
      });
    });
  });
}
