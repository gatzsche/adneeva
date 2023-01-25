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

import '../shared/endpoint.dart';
import '../shared/network_service.dart';

// #############################################################################

class BonjourServiceDeps {
  const BonjourServiceDeps();
  final newBonsoirBroadcast = BonsoirBroadcast.new;
  final newBonsoirDiscovery = BonsoirDiscovery.new;
  final bindServerSocket = ServerSocket.bind;
  final connectSocket = Socket.connect;
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
    _d = dependencies ??
        (isTest ? const MockBonjourServiceDeps() : const BonjourServiceDeps());
    _bonsoirBroadcast = _d.newBonsoirBroadcast(service: _bonsoirService);
    _bonsoirDiscovery = _d.newBonsoirDiscovery(type: service.type);
  }

  // ...........................................................................
  @override
  bool isSameService(BonsoirService a, BonsoirService b) {
    if (a is ResolvedBonsoirService && b is ResolvedBonsoirService) {
      return a.ip == b.ip && a.name == b.name && a.type == b.type;
    } else {
      return a.name == b.name && a.type == b.type;
    }
  }

  // ######################
  // Advertizing / Advertizer
  // ######################

  // ...........................................................................
  @override
  Future<void> startAdvertizing() async {
    bool needsStart = !_bonsoirBroadcast.isReady || _bonsoirBroadcast.isStopped;

    await _bonsoirBroadcast.ready;

    if (needsStart) {
      log?.call('Start advertizing on port ${_bonsoirBroadcast.service.port}');
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

    _serverSocket = await _d.bindServerSocket(
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
  // Discovering / Scanner
  // ######################
  Future<bool> isOwnService(ResolvedBonsoirService service) async {
    bool isOwnIp = service.ip != null && await isOwnIpAddress(service.ip!);
    if (isOwnIp && service.port == this.service.port) {
      return true;
    }
    return false;
  }

  // ...........................................................................
  @override
  Future<void> startScanning() async {
    await _listenToDiscoveryEvents();
    await _startDiscovery();
  }

  // ...........................................................................
  @override
  Future<void> stopScanning() async {
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
    final socket =
        await _d.connectSocket(ip, port, timeout: const Duration(seconds: 3));
    return socket;
  }

  // ...........................................................................
  Endpoint _initConnection(Socket socket) {
    return Endpoint<BonsoirService>(
      parentService: this,
      sendData: (data) async => socket.add(data),
      receiveData: socket.asBroadcastStream(),
      disconnect: socket.close,
      serviceInfo: service,
    );
  }

  // ...........................................................................
  Future<void> _listenToDiscoveryEvents() async {
    _needsStart = !_bonsoirDiscovery.isReady || _bonsoirDiscovery.isStopped;

    if (!_bonsoirDiscovery.isReady) {
      await _bonsoirDiscovery.ready;
    }

    if (_discoverySubscription == null) {
      log?.call('Listen to event stream');

      _discoverySubscription =
          _bonsoirDiscovery.eventStream?.listen((event) async {
        if (event.type == BonsoirDiscoveryEventType.DISCOVERY_SERVICE_FOUND) {
        } else if (event.type ==
            BonsoirDiscoveryEventType.DISCOVERY_SERVICE_RESOLVED) {
          final service = (event.service as ResolvedBonsoirService);
          final ip = service.ip;
          if (ip == null) {
            log?.call('Service with name "${service.name}" has no IP address');
            return;
          }

          // Ignore own service
          if (await isOwnService(service)) {
            return;
          }

          log?.call('Resolved service on port ${service.port}');
          onDiscoverService(service);
        } else if (event.type ==
            BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {
          log?.call(
              'Lost service on port ${(event.service as ResolvedBonsoirService).port}');
          onLooseService(event.service as ResolvedBonsoirService);
        } else if (event.type ==
            BonsoirDiscoveryEventType.DISCOVERY_SERVICE_RESOLVE_FAILED) {
          log?.call('Resolving failed');
        } else if (event.type == BonsoirDiscoveryEventType.DISCOVERY_STARTED) {
          log?.call('Discovery started');
        } else if (event.type == BonsoirDiscoveryEventType.DISCOVERY_STOPPED) {
          log?.call('Discovery stopped');
        }
      });
      _dispose.add(() => _discoverySubscription?.cancel);
    }
  }

  // ...........................................................................
  var _needsStart = false;

  Future<void> _startDiscovery() async {
    if (_needsStart) {
      log?.call('Start discovery');
      await _bonsoirDiscovery.start();
    }
  }
}
