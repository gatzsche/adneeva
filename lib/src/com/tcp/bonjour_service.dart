// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';

import '../../measure/types.dart';
import '../../utils/is_test.dart';
import 'mocks/mock_bonjour_service.dart';

import '../shared/connection.dart';
import '../shared/network_service.dart';

// #############################################################################

class BonjourServiceDeps {
  const BonjourServiceDeps();
  final bonsoirBroadcast = BonsoirBroadcast.new;
  final bonsoirDiscovery = BonsoirDiscovery.new;
  final serverSocketBind = ServerSocket.bind;
  final clientSocketConnect = Socket.connect;
  final listNetworkInterface = NetworkInterface.list;
}

// #############################################################################
class BonjourService
    extends NetworkService<BonsoirService, ResolvedBonsoirService> {
  // ...........................................................................
  BonjourService({
    required BonsoirService service,
    required NetworkServiceMode mode,
    Function(String)? log,
    String? name,
  })  : _bonsoirService = service,
        super(
          serviceInfo: service,
          mode: mode,
          name: name ?? 'BonjourService',
        ) {
    _d = isTest ? const MockBonjourServiceDeps() : const BonjourServiceDeps();
    _bonsoirBroadcast = _d.bonsoirBroadcast(service: _bonsoirService);
    _bonsoirDiscovery =
        _d.bonsoirDiscovery(type: '_mobile_network_evaluator._tcp');
  }

  // ######################
  // Advertizing / Master
  // ######################

  // ...........................................................................
  @override
  Future<void> startAdvertizing() async {
    bool needsStart = !_bonsoirBroadcast.isReady || _bonsoirBroadcast.isStopped;

    await _bonsoirBroadcast.ready;
    log?.call('Broadcasting on port ${_bonsoirBroadcast.service.port}');

    if (needsStart) {
      await _bonsoirBroadcast.start();
    }
  }

  // ...........................................................................
  @override
  Future<void> stopAdvertizing() async {
    await _bonsoirBroadcast.stop();
  }

  // ...........................................................................
  @override
  Future<void> startListeningForConnections() async {
    if (_serverSocket != null) {
      return;
    }

    log?.call('Binding to port ${serviceInfo.port}');

    _serverSocket = await _d.serverSocketBind(
      InternetAddress.anyIPv4,
      serviceInfo.port,
      shared: false,
    );

    _serverSocketSubscription = _serverSocket!.listen(
      (socket) {
        _initConnection(socket);
      },
    );
  }

  // ...........................................................................
  @override
  Future<void> stopListeningForConnections() async {
    _serverSocketSubscription?.cancel();
    _serverSocketSubscription = null;

    _serverSocket?.close();
    _serverSocket = null;
  }

  // ######################
  // Discovering / Slave
  // ######################

  @override
  Future<void> startDiscovery() async {
    bool needsStart = !_bonsoirDiscovery.isReady || _bonsoirDiscovery.isStopped;

    if (!_bonsoirDiscovery.isReady) {
      await _bonsoirDiscovery.ready;
    }

    if (needsStart) {
      await _bonsoirDiscovery.start();
    }

    if (_discoverySubscription == null) {
      _discoverySubscription =
          _bonsoirDiscovery.eventStream?.listen((event) async {
        if (event.type ==
            BonsoirDiscoveryEventType.DISCOVERY_SERVICE_RESOLVED) {
          final service = (event.service as ResolvedBonsoirService);
          final ip = service.ip;
          if (ip == null) {
            log?.call('Service with name "${service.name}" has no IP address');
            return;
          }

          // Ignore own service
          bool isOwnIp = await isOwnIpAddress(ip);
          if (isOwnIp && service.port == serviceInfo.port) {
            return;
          }

          log?.call('Discovered service on port ${service.port}');

          onDiscoverService(service);
        } else if (event.type ==
            BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {}
      });
      _dispose.add(() => _discoverySubscription?.cancel);
    }
  }

  // ...........................................................................
  @override
  Future<void> stopDiscovery() async {
    await _bonsoirDiscovery.stop();
  }

  // ...........................................................................
  @override
  Future<Connection> connectToDiscoveredService(
      ResolvedBonsoirService service) async {
    final clientSocket =
        await _connectClientSocket(ip: service.ip!, port: service.port);
    return _initConnection(clientSocket);
  }

  // ...........................................................................
  Future<List<String>> ownIpAddresses() async {
    final List<String> result = [];
    for (var interface in await _d.listNetworkInterface()) {
      for (var addr in interface.addresses) {
        result.add(addr.address);
      }
    }
    return result;
  }

  // ...........................................................................
  Future<bool> isOwnIpAddress(String ipAddress) async {
    if (ipAddress == '127.0.0.1' || ipAddress == 'localhost') {
      return true;
    }

    final ipAddresses = await ownIpAddresses();
    return ipAddresses.contains(ipAddress);
  }

  // ######################
  // Test
  // ######################

  @visibleForTesting
  BonsoirDiscovery get bonsoirDiscovery => _bonsoirDiscovery;

  @visibleForTesting
  BonsoirBroadcast get bonsoirBroadcast => _bonsoirBroadcast;

  @visibleForTesting
  ServerSocket? get serverSocket => _serverSocket;

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  late BonjourServiceDeps _d;

  final BonsoirService _bonsoirService;
  late BonsoirBroadcast _bonsoirBroadcast;
  ServerSocket? _serverSocket;
  StreamSubscription? _serverSocketSubscription;

  late BonsoirDiscovery _bonsoirDiscovery;
  StreamSubscription? _discoverySubscription;

  // ...........................................................................
  Future<Socket> _connectClientSocket(
      {required String ip, required int port}) async {
    try {
      log?.call('Client connects to port $port');
      final socket = await _d.clientSocketConnect(ip, port);
      return socket;
    }

    // coverage:ignore-start
    on SocketException catch (e) {
      log?.call(e.toString());
      rethrow;
    }
    // coverage:ignore-end
  }

  // ...........................................................................
  Connection _initConnection(Socket socket) {
    return Connection(
      parentService: this,
      sendData: (data) async => socket.add(data),
      receiveData: socket.asBroadcastStream(),
      disconnect: socket.close,
      serviceInfo: serviceInfo,
    );
  }
}
