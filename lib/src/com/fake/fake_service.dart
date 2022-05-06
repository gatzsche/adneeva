// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

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
  FakeService({required NetworkServiceMode mode})
      : super(
          serviceInfo: FakeServiceInfo(),
          mode: mode,
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

  // ...........................................................................
  static FakeService get master => exampleMasterFakeService();
  static FakeService get slave => exampleSlaveFakeService();

  // ...........................................................................
  @override
  Future<void> connectToDiscoveredService(service) {
    throw UnimplementedError();
  }

  // ...........................................................................
  @override
  Future<void> startAdvertizing() {
    throw UnimplementedError();
  }

  // ...........................................................................
  @override
  Future<void> startDiscovery() {
    throw UnimplementedError();
  }

  // ...........................................................................
  @override
  Future<void> startListeningForConnections() {
    throw UnimplementedError();
  }

  // ...........................................................................
  @override
  Future<void> stopAdvertizing() {
    throw UnimplementedError();
  }

  // ...........................................................................
  @override
  Future<void> stopDiscovery() {
    throw UnimplementedError();
  }

  // ...........................................................................
  @override
  Future<void> stopListeningForConnections() {
    throw UnimplementedError();
  }

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

// #############################################################################
FakeService exampleMasterFakeService() =>
    FakeService(mode: NetworkServiceMode.master);

FakeService exampleSlaveFakeService() =>
    FakeService(mode: NetworkServiceMode.slave);
