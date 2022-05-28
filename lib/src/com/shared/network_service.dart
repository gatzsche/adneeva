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
import 'endpoint.dart';

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

    if (role == EndpointRole.advertizer) {
      await _startAdvertizer();
    }

    if (role == EndpointRole.scanner) {
      await _startScanner();
    }
  }

  // ...........................................................................
  Future<void> stop() async {
    assert(_isStarted);

    if (role == EndpointRole.advertizer) {
      await _stopAdvertizer();
    }

    if (role == EndpointRole.scanner) {
      await _stopScanner();
    }

    _isStarted = false;
  }

  // ...........................................................................
  bool get isConnected => connectedEndpoints.value.isNotEmpty;

  // ...........................................................................
  bool isSameService(ServiceInfo a, ServiceInfo b);

  // ######################
  // Advertizing / Advertizer
  // ######################

  // ...........................................................................
  Future<void> startListeningForConnections();
  Future<void> startAdvertizing();
  Future<void> stopAdvertizing();
  Future<void> stopListeningForConnections();

  // ######################
  // Scanning / Scanner
  // ######################

  // ...........................................................................
  Future<void> startDiscovery();
  Future<void> stopDiscovery();

  // ######################
  // Connection
  // ######################

  // ...........................................................................
  Future<Endpoint> get firstConnection {
    if (_connectedEndpoints.value.isNotEmpty) {
      return Future.value(_connectedEndpoints.value.first);
    } else {
      return _newEndpoints.stream.first;
    }
  }

  // ...........................................................................
  @protected
  Future<void> connectToDiscoveredService(ResolvedServiceInfo service);

  // ...........................................................................
  void addConnection(Endpoint<ServiceInfo> endpoint) {
    assert(!_connectedEndpoints.value.contains(endpoint));
    _newEndpoints.add(endpoint);
    _connectedEndpoints.value = [..._connectedEndpoints.value, endpoint];
  }

  // ...........................................................................
  void removeConnection(Endpoint endpoint) {
    assert(_connectedEndpoints.value.contains(endpoint));
    endpoint.disconnect();
    _connectedEndpoints.value = [..._connectedEndpoints.value]
      ..remove(endpoint);
  }

  // ...........................................................................
  GgValueStream<List<Endpoint<ServiceInfo>>> get connectedEndpoints =>
      _connectedEndpoints.stream;

  // ...........................................................................
  Endpoint<ServiceInfo>? endpointForService(ServiceInfo serviceInfo) {
    for (final c in connectedEndpoints.value) {
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
  /// Implement this function to directly connect a advertizer service to a
  /// client service. This is needed for test purposes
  static Future<void> fakeConnect<ServiceInfo>(
    NetworkService endpointA,
    NetworkService endpointB,
  ) async {
    assert(endpointA.role != endpointB.role);
    assert(endpointA.runtimeType == endpointB.runtimeType);
    assert(endpointA.isStarted);
    assert(endpointB.isStarted);

    // Identify advertizer and scanner service
    final advertizer =
        endpointA.role == EndpointRole.advertizer ? endpointA : endpointB;
    final scanner =
        endpointA.role == EndpointRole.advertizer ? endpointB : endpointA;

    // Create a mock socket
    final MockSocket mockSocketAdvertizer =
        await MockSocket.connect('123.123.123.123', 12345);
    final mockSocketScanner = mockSocketAdvertizer.otherEndpoint;

    // Create two connections
    // advertizer listens to the scanners outgoing data stream
    // advertizer sends to its own outgoing data stream
    // ignore: unused_local_variable
    final advertizerConnection = Endpoint<ServiceInfo>(
      parentService: advertizer,
      disconnect: mockSocketAdvertizer.close,
      receiveData: mockSocketAdvertizer.dataIn.stream,
      sendData: (data) async {
        scheduleMicrotask(() {
          mockSocketAdvertizer.dataOut.add(data);
        });
      },
      serviceInfo: advertizer.service,
    );

    // scanner listens to the advertizer outgoing data stream
    // scanner sends to its own outgoing data stream
    // ignore: unused_local_variable
    final scannerConnection = Endpoint<ServiceInfo>(
      parentService: scanner,
      disconnect: mockSocketScanner.close,
      receiveData: mockSocketScanner.dataIn.stream,
      sendData: (data) async {
        scheduleMicrotask(() {
          mockSocketScanner.dataOut.add(data);
        });
      },
      serviceInfo: scanner.service,
    );
  }

  // ######################
  // Private
  // ######################

  void _init() {
    _initConnections();
  }

  final _newEndpoints = StreamController<Endpoint<ServiceInfo>>.broadcast();
  final _connectedEndpoints = GgValue<List<Endpoint<ServiceInfo>>>(seed: []);
  void _initConnections() {
    _dispose.add(_connectedEndpoints.dispose);
    _dispose.add(_newEndpoints.close);
  }

  final List<Function()> _dispose = [];
  bool _isStarted = false;

  // ...........................................................................
  @protected
  void onDiscoverService(ResolvedServiceInfo serviceInfo) {
    final c = endpointForService(serviceInfo);
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
    final c = endpointForService(serviceInfo);
    c?.disconnect();
  }

  // ...........................................................................
  Future<void> _disconnectAll() async {
    for (final c in [...connectedEndpoints.value]) {
      await c.disconnect();
    }
  }

  // ...........................................................................
  Future<void> _startScanner() async {
    await startDiscovery();
  }

  // ...........................................................................
  Future<void> _stopScanner() async {
    await stopDiscovery();
    await _disconnectAll();
  }

  // ...........................................................................
  Future<void> _startAdvertizer() async {
    await startListeningForConnections();
    await startAdvertizing();
  }

  // ...........................................................................
  Future<void> _stopAdvertizer() async {
    await stopAdvertizing();
    await stopListeningForConnections();
    await _disconnectAll();
  }
}
