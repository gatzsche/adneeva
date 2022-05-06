// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';

import '../../measure/types.dart';
import 'connection.dart';

// #############################################################################
abstract class NetworkService<ServiceInfo,
    ResolvedServiceInfo extends ServiceInfo> {
  NetworkService({
    required this.serviceInfo,
    required this.mode,
  }) {
    _init();
  }

  // ...........................................................................
  @mustCallSuper
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  Function(String)? log;

  // ...........................................................................
  final ServiceInfo serviceInfo;
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
  Future<void> stopDiscovery();

  // ######################
  // Connection
  // ######################

  // ...........................................................................
  Future<Connection> get firstConnection async => _connections.value.isNotEmpty
      ? _connections.value.first
      : await _newConnection.stream.first;

  // ...........................................................................
  @protected
  Future<void> connectToDiscoveredService(ResolvedServiceInfo service);

  // ...........................................................................
  void addConnection(Connection connection) {
    assert(!_connections.value.contains(connection));
    _newConnection.add(connection);
    _connections.value = [..._connections.value, connection];
  }

  // ...........................................................................
  void removeConnection(Connection connection) {
    assert(_connections.value.contains(connection));
    connection.disconnect();
    _connections.value = [..._connections.value]..remove(connection);
  }

  // ...........................................................................
  GgValueStream<List<Connection>> get connections => _connections.stream;

  // ...........................................................................
  Connection? connectionForService(ServiceInfo serviceInfo) {
    for (final c in connections.value) {
      if (c.serviceInfo == serviceInfo) {
        return c;
      }
    }

    return null;
  }

  // ######################
  // Private
  // ######################

  void _init() {
    _initConnections();
  }

  final _newConnection = StreamController<Connection>.broadcast();
  final _connections = GgValue<List<Connection>>(seed: []);
  void _initConnections() {
    _dispose.add(_connections.dispose);
    _dispose.add(_newConnection.close);
  }

  final List<Function()> _dispose = [];

  // ...........................................................................
  @protected
  void onDiscoverService(ResolvedServiceInfo serviceInfo) {
    final c = connectionForService(serviceInfo);
    assert(c == null);
    if (c == null) {
      connectToDiscoveredService(serviceInfo);
    }
  }

  // ...........................................................................
  Future<void> _disconnectAll() async {
    for (final c in [...connections.value]) {
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
