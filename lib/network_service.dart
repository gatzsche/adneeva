// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import './connection.dart';

// #############################################################################
enum NetworkServiceMode {
  master,
  slave,
  masterAndSlave,
}

// #############################################################################
abstract class NetworkService<ServiceDescription> {
  NetworkService({
    required this.serviceDescription,
    required this.mode,
  }) {
    _listenToDiscoveredServices();
  }

  // ...........................................................................
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  Function(String)? log;

  // ...........................................................................
  final ServiceDescription serviceDescription;
  final NetworkServiceMode mode;

  // ...........................................................................
  Future<void> start() async {
    if (mode == NetworkServiceMode.master ||
        mode == NetworkServiceMode.masterAndSlave) {
      await _startMaster();
    }

    if (mode == NetworkServiceMode.slave ||
        mode == NetworkServiceMode.masterAndSlave) {
      await _startSlave();
    }
  }

  // ...........................................................................
  Future<void> stop() async {
    if (mode == NetworkServiceMode.master ||
        mode == NetworkServiceMode.masterAndSlave) {
      await _stopMaster();
    }

    if (mode == NetworkServiceMode.slave ||
        mode == NetworkServiceMode.masterAndSlave) {
      await _stopSlave();
    }
  }

  // ######################
  // Advertizing / Master
  // ######################

  // ...........................................................................
  Future<void> startListeningForConnections();
  Future<void> startAdvertizing();
  Future<void> stopAdvertizing();
  Future<void> stopListeningForConnections();

  // ######################
  // Scanning / Slave
  // ######################

  // ...........................................................................
  Future<void> startDiscovery();
  Stream<ServiceDescription> get discoveredServices;
  Future<void> stopDiscovery();

  // ######################
  // Connection
  // ######################

  // ...........................................................................
  Future<void> connectToDiscoveredService(ServiceDescription service);

  // ...........................................................................
  void addConnection(Connection connection) {
    assert(!_connections.contains(connection));
    _connections.add(connection);
  }

  // ...........................................................................
  void removeConnection(Connection connection) {
    assert(_connections.contains(connection));
    connection.disconnect();
    _connections.remove(connection);
  }

  // ...........................................................................
  List<Connection> get connections => _connections;

  // ######################
  // Private
  // ######################

  final List<Connection> _connections = [];

  final List<Function()> _dispose = [];

  // ...........................................................................
  void _listenToDiscoveredServices() {
    scheduleMicrotask(
      () {
        final s = discoveredServices.listen(
          (service) => connectToDiscoveredService(service),
        );

        _dispose.add(s.cancel);
      },
    );
  }

  // ...........................................................................
  Future<void> _disconnectAll() async {
    for (final c in [...connections]) {
      await c.disconnect();
    }
  }

  // ...........................................................................
  Future<void> _startSlave() async {
    await startDiscovery();
  }

  // ...........................................................................
  Future<void> _stopSlave() async {
    await stopDiscovery();
  }

  // ...........................................................................
  Future<void> _startMaster() async {
    await startListeningForConnections();
    await startAdvertizing();
    await _disconnectAll();
  }

  // ...........................................................................
  Future<void> _stopMaster() async {
    await stopAdvertizing();
    await stopListeningForConnections();
    await _disconnectAll();
  }
}
