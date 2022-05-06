// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';

import 'mocks/mock_bonjour_service.dart';

import '../connection.dart';
import '../network_service.dart';

// #############################################################################
class BonjourServiceDescription {
  BonjourServiceDescription({
    required this.serviceId,
    required this.ipAddress,
    required this.port,
    required this.name,
  });

  final String serviceId;
  final String ipAddress;
  final String name;
  final int port;
}

// #############################################################################

class BonjourServiceDeps {
  const BonjourServiceDeps();
  final bonsoirBroadcast = BonsoirBroadcast.new;
  final bonsoirDiscovery = BonsoirDiscovery.new;
  final serverSocketBind = ServerSocket.bind;
  final clientSocketConnect = Socket.connect;
  final listNetworkInterface = NetworkInterface.list;
}

final isTest = Platform.environment.containsKey('FLUTTER_TEST');

// #############################################################################
class BonjourService extends NetworkService<BonjourServiceDescription> {
  // ...........................................................................
  BonjourService({
    required BonjourServiceDescription description,
    required NetworkServiceMode mode,
    Function(String)? log,
  })  : _bonsoirService = createBonsoirService(description),
        super(
          serviceDescription: description,
          mode: mode,
        ) {
    _d = isTest ? const MockBonjourServiceDeps() : const BonjourServiceDeps();
    _bonsoirBroadcast = _d.bonsoirBroadcast(service: _bonsoirService);
    _bonsoirDiscovery = _d.bonsoirDiscovery(
        type: '_mobile_network_evaluator._tcp'); // serviceDescription.serviceId
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

    log?.call('Binding to port ${serviceDescription.port}');

    _serverSocket = await _d.serverSocketBind(
      InternetAddress.anyIPv4,
      serviceDescription.port,
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
          if (isOwnIp && service.port == serviceDescription.port) {
            return;
          }

          log?.call('Discovered service on port ${service.port}');

          final discoveredService = BonjourServiceDescription(
            ipAddress: ip,
            serviceId: serviceDescription.serviceId,
            name: service.name,
            port: service.port,
          );

          _discoveredServices.add(discoveredService);
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
  Stream<BonjourServiceDescription> get discoveredServices =>
      _discoveredServices.stream;

  // ...........................................................................
  @override
  Future<void> connectToDiscoveredService(
      BonjourServiceDescription service) async {
    final clientSocket =
        await _connectClientSocket(ip: service.ipAddress, port: service.port);
    _initConnection(clientSocket);
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

  // ...........................................................................
  static BonsoirService createBonsoirService(BonjourServiceDescription d) {
    return BonsoirService(
      name: d.name,
      port: d.port,
      type: d.serviceId,
    );
  }

  late BonsoirDiscovery _bonsoirDiscovery;
  StreamSubscription? _discoverySubscription;
  final _discoveredServices = StreamController<BonjourServiceDescription>();

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
  void _initConnection(Socket socket) {
    Connection(
      parentService: this,
      sendData: (data) async => socket.add(data),
      receiveData: socket.asBroadcastStream(),
      disconnect: socket.close,
    );
  }
}
