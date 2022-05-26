// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';

import '../../utils/is_test.dart';
import 'mocks/mock_bonjour_service.dart';

import '../shared/connection.dart';
import '../shared/network_service.dart';
import '../../measure/types.dart';

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
    required super.service,
    required super.role,
    super.log,
    String? name,
    BonjourServiceDeps? dependencies,
  })  : _bonsoirService = service,
        super(name: name ?? 'BonjourService') {
    log?.call(
        'Set up bonjour "${service.name} - ${role == EndpointRole.master ? 'Master' : 'Slave'}"');
    _d = dependencies ??
        (isTest ? const MockBonjourServiceDeps() : const BonjourServiceDeps());
    _bonsoirBroadcast = _d.bonsoirBroadcast(service: _bonsoirService);
    _bonsoirDiscovery = _d.bonsoirDiscovery(type: service.type);
  }

  // ######################
  // Advertizing / Master
  // ######################

  // ...........................................................................
  @override
  Future<void> startAdvertizing() async {
    bool needsStart = !_bonsoirBroadcast.isReady || _bonsoirBroadcast.isStopped;

    await _bonsoirBroadcast.ready;
    log?.call(
        'Broadcasting "${service.type}" on port ${_bonsoirBroadcast.service.port}');

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

    log?.call('Bind to port ${service.port}');

    _serverSocket = await _d.serverSocketBind(
      InternetAddress.anyIPv4,
      service.port,
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
      log?.call('Start discovering service "${service.type}" ');

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

          log?.call(
              'Discovered service "${service.name}" on port ${service.port}');

          // Ignore own service
          bool isOwnIp = await isOwnIpAddress(ip);
          if (isOwnIp && service.port == this.service.port) {
            log?.call('Do not connect because its the own service.');
            return;
          }

          onDiscoverService(service);
        } else if (event.type ==
            BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {
          log?.call('Lost service "${service.name}"');
          onLooseService(event.service as ResolvedBonsoirService);
        }
      });
      _dispose.add(() => _discoverySubscription?.cancel);
    }
  }

  // ...........................................................................
  @override
  Future<void> stopDiscovery() async {
    await _bonsoirDiscovery.stop();
    _discoverySubscription?.cancel();
    _discoverySubscription = null;
  }

  // ...........................................................................
  @override
  Future<void> connectToDiscoveredService(
    ResolvedBonsoirService service,
  ) async {
    try {
      final clientSocket =
          await _connectClientSocket(ip: service.ip!, port: service.port);
      _initConnection(clientSocket);
    } on SocketException catch (e) {
      log?.call(e.toString());
    }
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
    log?.call('Client connects to port $port');
    final socket = await _d.clientSocketConnect(ip, port);
    return socket;
  }

  // ...........................................................................
  Connection _initConnection(Socket socket) {
    return Connection(
      parentService: this,
      sendData: (data) async => socket.add(data),
      receiveData: socket.asBroadcastStream(),
      disconnect: socket.close,
      serviceInfo: service,
    );
  }
}
