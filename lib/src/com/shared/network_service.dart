// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';

import '../../measure/types.dart';
import '../tcp/mocks/mock_socket.dart';
import 'connection.dart';

// #############################################################################
abstract class NetworkService<ServiceInfo,
    ResolvedServiceInfo extends ServiceInfo> {
  NetworkService({
    required this.service,
    required this.role,
    this.name = 'NetworkService',
    this.log,
  }) {
    _init();
  }

  // ...........................................................................
  final String name;

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
  final ServiceInfo service;
  final EndpointRole role;

  // ...........................................................................
  bool get isStarted => _isStarted;

  // ...........................................................................
  Future<void> start() async {
    assert(!_isStarted);
    _isStarted = true;

    if (role == EndpointRole.master) {
      await _startMaster();
    }

    if (role == EndpointRole.slave) {
      await _startSlave();
    }
  }

  // ...........................................................................
  Future<void> stop() async {
    assert(_isStarted);

    if (role == EndpointRole.master) {
      await _stopMaster();
    }

    if (role == EndpointRole.slave) {
      await _stopSlave();
    }

    _isStarted = false;
  }

  // ...........................................................................
  bool get isConnected => connections.value.isNotEmpty;

  // ...........................................................................
  bool isSameService(ResolvedServiceInfo a, ResolvedServiceInfo b);

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
  Future<Connection> get firstConnection {
    if (_connections.value.isNotEmpty) {
      return Future.value(_connections.value.first);
    } else {
      return _newConnection.stream.first;
    }
  }

  // ...........................................................................
  @protected
  Future<void> connectToDiscoveredService(ResolvedServiceInfo service);

  // ...........................................................................
  void addConnection(Connection<ResolvedServiceInfo> connection) {
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
  GgValueStream<List<Connection<ResolvedServiceInfo>>> get connections =>
      _connections.stream;

  // ...........................................................................
  Connection<ResolvedServiceInfo>? connectionForService(
      ResolvedServiceInfo serviceInfo) {
    for (final c in connections.value) {
      if (isSameService(c.serviceInfo, serviceInfo)) {
        return c;
      }
    }

    return null;
  }

  // ######################
  // Test
  // ######################

  // ...........................................................................
  /// Implement this function to directly connect a master service to a
  /// client service. This is needed for test purposes
  static Future<void> fakeConnect(
    NetworkService endpointA,
    NetworkService endpointB,
  ) async {
    assert(endpointA.role != endpointB.role);
    assert(endpointA.runtimeType == endpointB.runtimeType);
    assert(endpointA.isStarted);
    assert(endpointB.isStarted);

    // Identify master and slave service
    final master =
        endpointA.role == EndpointRole.master ? endpointA : endpointB;
    final slave = endpointA.role == EndpointRole.master ? endpointB : endpointA;

    // Create a mock socket
    final MockSocket mockSocketMaster =
        await MockSocket.connect('123.123.123.123', 12345);
    final mockSocketSlave = mockSocketMaster.otherEndpoint;

    // Create two connections
    // master listens to the slaves outgoing data stream
    // master sends to its own outgoing data stream
    // ignore: unused_local_variable
    final masterConnection = Connection(
      parentService: master,
      disconnect: mockSocketMaster.close,
      receiveData: mockSocketMaster.dataIn.stream,
      sendData: (data) async {
        scheduleMicrotask(() {
          mockSocketMaster.dataOut.add(data);
        });
      },
      serviceInfo: master.service,
    );

    // slave listens to the master outgoing data stream
    // slave sends to its own outgoing data stream
    // ignore: unused_local_variable
    final slaveConnection = Connection(
      parentService: slave,
      disconnect: mockSocketSlave.close,
      receiveData: mockSocketSlave.dataIn.stream,
      sendData: (data) async {
        scheduleMicrotask(() {
          mockSocketSlave.dataOut.add(data);
        });
      },
      serviceInfo: slave.service,
    );
  }

  // ######################
  // Private
  // ######################

  void _init() {
    _initConnections();
  }

  final _newConnection = StreamController<Connection>.broadcast();
  final _connections = GgValue<List<Connection<ResolvedServiceInfo>>>(seed: []);
  void _initConnections() {
    _dispose.add(_connections.dispose);
    _dispose.add(_newConnection.close);
  }

  final List<Function()> _dispose = [];
  bool _isStarted = false;

  // ...........................................................................
  @protected
  void onDiscoverService(ResolvedServiceInfo serviceInfo) {
    final c = connectionForService(serviceInfo);
    assert(c == null);
    if (c == null) {
      connectToDiscoveredService(serviceInfo).onError(
        (error, stackTrace) {
          log?.call('Error while connecting to a discovered service.');
        },
      );
    }
  }

  // ...........................................................................
  @protected
  void onLooseService(ResolvedServiceInfo serviceInfo) {
    final c = connectionForService(serviceInfo);
    c?.disconnect();
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
    await _disconnectAll();
  }

  // ...........................................................................
  Future<void> _startMaster() async {
    await startListeningForConnections();
    await startAdvertizing();
  }

  // ...........................................................................
  Future<void> _stopMaster() async {
    await stopAdvertizing();
    await stopListeningForConnections();
    await _disconnectAll();
  }
}
