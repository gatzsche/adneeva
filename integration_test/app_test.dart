// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_network_evaluator/application.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Application', () {
    testWidgets('Should work correctly', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // ..........................
      // Create AppA and AppB
      final appA = Application();
      final appB = Application();
      await appA.waitUntilConnected;
      await appB.waitUntilConnected;

      // ...........................................
      // Wait until both applications have connected

      // .......................................
      // Set the first application into tcp mode

      // AppA should create a server socket with a given port

      // AppA should tell to switch to tcp mode

      // AppB should connect to the tcp mode port

      // AppB should have informed AppA that it is ready for measuremnt

      // AppA should start the measurments

      // AppA should tell AppB to close the TCP mode

      // .......................................
      // Set the first application into nearby mode

      // AppA should start a nearby service

      // AppA should have told AppB about the nearby service

      // AppB should connect to nearby mode

      // AppB should have told AppA that it is ready for measurment

      // AppA should start the measurments

      // AppA should tell AppB to close Nearby mode
    });
  });
}
