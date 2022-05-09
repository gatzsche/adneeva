// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'package:gg_value/gg_value.dart';

import '../../measure/types.dart';
import '../shared/network_service.dart';

// .............................................................................
class FakeServiceInfo {}

// .............................................................................
class ResolvedFakeServiceInfo extends FakeServiceInfo {}

class FakeService
    extends NetworkService<FakeServiceInfo, ResolvedFakeServiceInfo> {
  // ...........................................................................
  FakeService({required EndpointRole slave})
      : super(
          serviceInfo: FakeServiceInfo(),
          role: slave,
          name: slave == EndpointRole.master
              ? 'MasterFakeService'
              : 'SlaveFakeService',
        ) {
    _init();
  }

  // ...........................................................................
  @override
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }

    super.dispose();
  }

  // ...............................................
  // Provide references to master and slave services

  static FakeService get master => FakeService(slave: EndpointRole.master);
  static FakeService get slave => FakeService(slave: EndpointRole.slave);

  // ..............................................
  // Advertize - Not implemented for fake service

  @override
  Future<void> startAdvertizing() async {}

  @override
  Future<void> stopAdvertizing() async {}

  @override
  Future<void> startListeningForConnections() async {}

  // ..............................................
  // Discovery - Not implemented for fake service

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  // ................
  // Connect services

  // coverage:ignore-start
  @override
  Future<void> connectToDiscoveredService(service) async {}
  // coverage:ignore-end

  // ...........................................................................
  @override
  Future<void> stopListeningForConnections() async {}

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];

  final _discoveredServices = GgValue<List<ResolvedFakeServiceInfo>>(seed: []);

  // ...........................................................................
  void _init() {
    _initDiscoveredServices();
  }

  // ...........................................................................
  void _initDiscoveredServices() {
    _dispose.add(_discoveredServices.dispose);
  }
}
