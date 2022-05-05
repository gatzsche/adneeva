// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/bonjour_service/bonjour_service.dart';
import 'package:mobile_network_evaluator/network_service.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late BonjourService master;
  late BonjourService slave;

  group('BonjourService', () {
    void init() {
      master = exampleBonjourService(NetworkServiceMode.master);
      slave = exampleBonjourService(NetworkServiceMode.slave);
    }

    void dispose() {
      master.dispose();
      slave.dispose();
    }

    test('should work correctly', () {
      fakeAsync((fake) {
        init();

        // initializes master and slave correctly
        expect(master, isNotNull);
        expect(slave, isNotNull);
        fake.flushMicrotasks();

        // ...........
        // Start slave
        // => Slave should scan for the service
        slave.start();
        fake.flushMicrotasks();

        // ............
        // Start master
        // => A tcp server should be started listening for connections
        // => The service should be broadcasted
        master.start();
        fake.flushMicrotasks();

        // .....................................
        // After master has started broadcasting,
        // => Client should discover the broadcasted service
        // => Client should connect to broadcasted service

        dispose();
      });
    });
  });
}
