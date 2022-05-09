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
    test('should initialize both, a master and a slave endpoint', () {
      fakeAsync((fake) {
        init(fake);
        expect(bipolarEndpoint, isNotNull);
        expect(bipolarEndpoint.master, isNotNull);
        expect(bipolarEndpoint.slave, isNotNull);

        expect(
          bipolarEndpoint.service(EndpointRole.master),
          bipolarEndpoint.master,
        );
        expect(
          bipolarEndpoint.service(EndpointRole.slave),
          bipolarEndpoint.slave,
        );

        dispose(fake);
      });
    });

    test('should start and stop both, a master and a slave endpoint', () {
      fakeAsync((fake) {
        init(fake);
        expect(bipolarEndpoint.master.isStarted, false);
        expect(bipolarEndpoint.slave.isStarted, false);
        bipolarEndpoint.start();
        fake.flushMicrotasks();
        expect(bipolarEndpoint.master.isStarted, true);
        expect(bipolarEndpoint.slave.isStarted, true);

        bipolarEndpoint.stop();
        fake.flushMicrotasks();
        expect(bipolarEndpoint.master.isStarted, false);
        expect(bipolarEndpoint.slave.isStarted, false);
        dispose(fake);
      });
    });
  });
}
