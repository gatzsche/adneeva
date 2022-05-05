// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

import '../connection.dart';
import '../network_service.dart';
import 'bonjour_service_core.dart';

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
class BonjourService extends NetworkService<BonjourServiceDescription> {
  // ...........................................................................
  BonjourService({
    required BonjourServiceDescription description,
    required NetworkServiceMode mode,
  })  : _bonsoirService = createBonsoirService(description),
        super(
          serviceDescription: description,
          mode: mode,
        ) {
    _bonsoirBroadcast = BonsoirBroadcast(service: _bonsoirService);
    _bonsoirDiscovery = BonsoirDiscovery(type: serviceDescription.serviceId);
  }

  // ######################
  // Advertizing / Master
  // ######################

  // ...........................................................................
  @override
  Future<void> startAdvertizing() async {
    await _bonsoirBroadcast.ready;

    if (_bonsoirBroadcast.isStopped) {
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

    _serverSocket = await ServerSocket.bind(
      serviceDescription.ipAddress,
      serviceDescription.port,
      shared: true,
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
    if (!_bonsoirDiscovery.isReady) {
      await _bonsoirDiscovery.ready;
    }

    if (_bonsoirDiscovery.isStopped) {
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
            throw StateError(
              'Service with name %{service.name} has no IP address',
            );
          }

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
    _discoverySubscription?.cancel();
    _discoverySubscription = null;
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

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];

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
  late StreamSubscription? _discoverySubscription;
  final _discoveredServices = StreamController<BonjourServiceDescription>();

  // ...........................................................................
  Future<Socket> _connectClientSocket(
      {required String ip, required int port}) async {
    try {
      final socket = await Socket.connect(ip, port);
      return socket;
    } on SocketException {
      throw StateError('Error while connecting to tcp client');
    }
  }

  // ...........................................................................
  void _initConnection(Socket socket) {
    Connection(
      parentService: this,
      sendString: (stringData) async => socket.write(stringData),
      receiveData: socket,
      disconnect: socket.close,
    );
  }
}

// #############################################################################
BonjourService exampleBonjourService(NetworkServiceMode mode) {
  final description = BonjourServiceDescription(
    ipAddress: '127.0.0.1',
    name: 'Example Bonjour Service',
    port: 12457,
    serviceId: 'example.bonjour.service',
  );

  return BonjourService(
    description: description,
    mode: mode,
  );
}
