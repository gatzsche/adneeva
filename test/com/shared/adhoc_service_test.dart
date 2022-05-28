// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mobile_network_evaluator/src/com/fake/fake_service.dart';
import 'package:mobile_network_evaluator/src/com/shared/adHoc_service.dart';
import 'package:mobile_network_evaluator/src/measure/types.dart';

void main() {
  late AdHocService<FakeService> adHocEndpoint;

  void init(FakeAsync fake) {
    adHocEndpoint = exampleBipolarEndpoint();
    fake.flushMicrotasks();
  }

  void dispose(FakeAsync fake) {
    adHocEndpoint.dispose();
    fake.flushMicrotasks();
    fake.flushMicrotasks();
  }

  group('AdHocEndpoint', () {
    // #########################################################################
    test('should initialize both, a advertizer and a scanner endpoint', () {
      fakeAsync((fake) {
        init(fake);
        expect(adHocEndpoint, isNotNull);
        expect(adHocEndpoint.advertizer, isNotNull);
        expect(adHocEndpoint.scanner, isNotNull);

        expect(
          adHocEndpoint.service(EndpointRole.advertizer),
          adHocEndpoint.advertizer,
        );
        expect(
          adHocEndpoint.service(EndpointRole.scanner),
          adHocEndpoint.scanner,
        );

        dispose(fake);
      });
    });

    test('should start and stop both, a advertizer and a scanner endpoint', () {
      fakeAsync((fake) {
        init(fake);
        expect(adHocEndpoint.advertizer.isStarted, false);
        expect(adHocEndpoint.scanner.isStarted, false);
        adHocEndpoint.start();
        fake.flushMicrotasks();
        expect(adHocEndpoint.advertizer.isStarted, true);
        expect(adHocEndpoint.scanner.isStarted, true);

        adHocEndpoint.stop();
        fake.flushMicrotasks();
        expect(adHocEndpoint.advertizer.isStarted, false);
        expect(adHocEndpoint.scanner.isStarted, false);
        dispose(fake);
      });
    });
  });
}
