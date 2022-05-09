// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:typed_data';

import 'package:gg_value/gg_value.dart';

import '../../measure/types.dart';
import '../shared/connection.dart';
import '../shared/network_service.dart';

// .............................................................................
class FakeServiceInfo {}

// .............................................................................
class ResolvedFakeServiceInfo extends FakeServiceInfo {
  ResolvedFakeServiceInfo({
    required this.masterService,
    required this.slaveService,
  }) {
    assert(masterService.mode == NetworkServiceMode.master);
    assert(slaveService.mode == NetworkServiceMode.slave);
  }

  final FakeService masterService;
  final FakeService slaveService;
}

class FakeService
    extends NetworkService<FakeServiceInfo, ResolvedFakeServiceInfo> {
  // ...........................................................................
  FakeService({required NetworkServiceMode mode})
      : super(
          serviceInfo: FakeServiceInfo(),
          mode: mode,
          name: mode == NetworkServiceMode.master
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

  static FakeService get master => FakeService(mode: NetworkServiceMode.master);
  static FakeService get slave => FakeService(mode: NetworkServiceMode.slave);

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
  Future<void> connectTo(FakeService masterService) async {
    assert(isStarted);
    assert(mode == NetworkServiceMode.slave);
    assert(masterService.mode == NetworkServiceMode.master);

    onDiscoverService(
      ResolvedFakeServiceInfo(
        masterService: masterService,
        slaveService: this,
      ),
    );
  }

  // ...........................................................................
  @override
  Future<void> connectToDiscoveredService(service) async {
    assert(service.slaveService == this);

    // Create two outgoing data stream
    // One for master
    // One for slave
    final masterOutgoingDataStream = StreamController<Uint8List>.broadcast();
    final slaveOutgoingDataStream = StreamController<Uint8List>.broadcast();

    // Create two connections
    // master listens to the slaves outgoing data stream
    // master sends to its own outgoing data stream
    // ignore: unused_local_variable
    final masterConnection = Connection(
      parentService: service.masterService,
      disconnect: masterOutgoingDataStream.close,
      receiveData: slaveOutgoingDataStream.stream,
      sendData: (data) async {
        scheduleMicrotask(() {
          masterOutgoingDataStream.add(data);
        });
      },
      serviceInfo: service,
    );

    // slave listens to the master outgoing data stream
    // slave sends to its own outgoing data stream
    // ignore: unused_local_variable
    final slaveConnection = Connection(
      parentService: this,
      disconnect: slaveOutgoingDataStream.close,
      receiveData: masterOutgoingDataStream.stream,
      sendData: (data) async {
        scheduleMicrotask(() {
          slaveOutgoingDataStream.add(data);
        });
      },
      serviceInfo: serviceInfo,
    );
  }

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
