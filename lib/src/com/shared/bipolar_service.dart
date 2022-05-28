// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../../measure/types.dart';
import '../fake/fake_service.dart';
import 'network_service.dart';

class BipolarService<T extends NetworkService<dynamic, dynamic>> {
  BipolarService({required this.advertizer, required this.scanner}) {
    _init();
  }

  final T advertizer;
  final T scanner;

  // ...........................................................................
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  Future<void> start() async {
    advertizer.start();
    scanner.start();
  }

  // ...........................................................................
  Future<void> stop() async {
    advertizer.stop();
    scanner.stop();
  }

  // ...........................................................................
  T service(EndpointRole role) =>
      role == EndpointRole.advertizer ? advertizer : scanner;

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  void _init() {
    _dispose.add(advertizer.dispose);
    _dispose.add(scanner.dispose);
  }
}

// #############################################################################
BipolarService<FakeService> exampleBipolarEndpoint() => BipolarService(
      advertizer: FakeService(scanner: EndpointRole.advertizer),
      scanner: FakeService(scanner: EndpointRole.scanner),
    );
