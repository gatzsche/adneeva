// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/com/shared/bipolar_service.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late BipolarService<FakeService> bipolarEndpoint;

  void init(FakeAsync fake) {
    bipolarEndpoint = exampleBipolarEndpoint();
    fake.flushMicrotasks();
  }

  void dispose(FakeAsync fake) {
    bipolarEndpoint.dispose();
    fake.flushMicrotasks();
    fake.flushMicrotasks();
  }

  group('AdhocEndpoint', () {
    // #########################################################################
    test('should initialize both, a advertizer and a scanner endpoint', () {
      fakeAsync((fake) {
        init(fake);
        expect(bipolarEndpoint, isNotNull);
        expect(bipolarEndpoint.advertizer, isNotNull);
        expect(bipolarEndpoint.scanner, isNotNull);

        expect(
          bipolarEndpoint.service(EndpointRole.advertizer),
          bipolarEndpoint.advertizer,
        );
        expect(
          bipolarEndpoint.service(EndpointRole.scanner),
          bipolarEndpoint.scanner,
        );

        dispose(fake);
      });
    });

    test('should start and stop both, a advertizer and a scanner endpoint', () {
      fakeAsync((fake) {
        init(fake);
        expect(bipolarEndpoint.advertizer.isStarted, false);
        expect(bipolarEndpoint.scanner.isStarted, false);
        bipolarEndpoint.start();
        fake.flushMicrotasks();
        expect(bipolarEndpoint.advertizer.isStarted, true);
        expect(bipolarEndpoint.scanner.isStarted, true);

        bipolarEndpoint.stop();
        fake.flushMicrotasks();
        expect(bipolarEndpoint.advertizer.isStarted, false);
        expect(bipolarEndpoint.scanner.isStarted, false);
        dispose(fake);
      });
    });
  });
}
