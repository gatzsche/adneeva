// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../../measure/types.dart';
import '../fake/fake_service.dart';
import 'network_service.dart';

class BipolarService<T extends NetworkService<dynamic, dynamic>> {
  BipolarService({required this.master, required this.slave}) {
    _init();
  }

  final T master;
  final T slave;

  // ...........................................................................
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  Future<void> start() async {
    master.start();
    slave.start();
  }

  // ...........................................................................
  Future<void> stop() async {
    master.stop();
    slave.stop();
  }

  // ...........................................................................
  T service(EndpointRole role) => role == EndpointRole.master ? master : slave;

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  void _init() {
    _dispose.add(master.dispose);
    _dispose.add(slave.dispose);
  }
}

// #############################################################################
BipolarService<FakeService> exampleBipolarEndpoint() => BipolarService(
      master: FakeService(slave: EndpointRole.master),
      slave: FakeService(slave: EndpointRole.slave),
    );
