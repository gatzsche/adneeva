// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import '../../measure/types.dart';
import '../shared/network_service.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

class NearbyServiceInfo {}

class ResolvedNearbyServiceInfo extends NearbyServiceInfo {}

class NeabyService
    extends NetworkService<NearbyServiceInfo, ResolvedNearbyServiceInfo> {
  NeabyService({
    required super.service,
    required super.role,
    required super.log,
  }) {
    _initNearby();
  }

  // ...........................................................................
  @override
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
    super.dispose();
  }

  // ######################
  // Advertizing / Master
  // ######################

  // ...........................................................................
  @override
  Future<void> startAdvertizing() async {
    if (_isAdvertizing) {
      return;
    }
    _isAdvertizing = true;
    await _isInitialized.future;
    await _nearbyService.startAdvertisingPeer();
  }

  // ...........................................................................
  @override
  Future<void> stopAdvertizing() async {
    if (!_isAdvertizing) {
      return;
    }
    _isAdvertizing = false;
    await _nearbyService.stopAdvertisingPeer();
  }

  // ...........................................................................
  @override
  Future<void> startListeningForConnections() async {}

  // ...........................................................................
  @override
  Future<void> stopListeningForConnections() async {}

  // ######################
  // Discovering / Slave
  // ######################

  // ...........................................................................
  @override
  Future<void> startDiscovery() async {
    if (_isDiscovering) {
      return;
    }

    _isDiscovering = true;
    await _isInitialized.future;
    await _nearbyService.startBrowsingForPeers();

    _discoverySubscription =
        _nearbyService.stateChangedSubscription(callback: (devicesList) {
      // TODO: CONNECT TO FOUND DEVICES
    });

    _dispose.add(() => _discoverySubscription?.cancel);
  }

  // ...........................................................................
  @override
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) {
      return;
    }
    _isDiscovering = false;
    await _nearbyService.stopBrowsingForPeers();
  }

  // ...........................................................................
  @override
  Future<void> connectToDiscoveredService(
    ResolvedNearbyServiceInfo service,
  ) async {}

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  final _isInitialized = Completer<void>();
  bool _isAdvertizing = false;
  bool _isDiscovering = false;
  StreamSubscription? _discoverySubscription;

  late NearbyService _nearbyService;

  void _initNearby() async {
    _nearbyService = NearbyService();
    await _nearbyService.init(
      serviceType: 'mobile_network_evaluator_measure_nearby',
      deviceName: role == EndpointRole.master ? 'Master' : 'Slave',
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          _isInitialized.complete();
        }
      },
    );
  }
}
