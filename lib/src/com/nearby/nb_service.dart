// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../measure/types.dart';
import '../../utils/is_test.dart';
import '../shared/connection.dart';
import '../shared/network_service.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

import 'mock_nb_service.dart';

// #############################################################################

class NbServiceDeps {
  const NbServiceDeps();
  final newNearbyService = NearbyService.new;
}

// #############################################################################

class NbServiceInfo {
  const NbServiceInfo();
}

class ResolvedNbServiceInfo extends NbServiceInfo {
  ResolvedNbServiceInfo(this.device);
  final receivedData = StreamController<Uint8List>.broadcast();
  final Device device;
}

// #############################################################################
class NbService extends NetworkService<NbServiceInfo, ResolvedNbServiceInfo> {
  NbService({
    required super.service,
    required super.role,
    required super.log,
    NbServiceDeps? dependencies,
  }) : _d = dependencies ??
            (isTest ? const MockNbServiceDeps() : const NbServiceDeps()) {
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

  // ...........................................................................
  final NbServiceDeps _d;

  // ...........................................................................
  @override
  bool isSameService(ResolvedNbServiceInfo a, ResolvedNbServiceInfo b) =>
      a.device.deviceId == b.device.deviceId;

  // ######################
  // Advertizing / Advertizer
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
  // Discovering / Scanner
  // ######################

  // ...........................................................................
  @override
  Future<void> startDiscovery() async {
    if (_isDiscovering) {
      return;
    }
    _isDiscovering = true;

    await _isInitialized.future;
    await _startBrowsingForPeers;
    await _startListeningForData;
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

  // ######################
  // Common
  // ######################

  // ...........................................................................
  @override
  Future<void> connectToDiscoveredService(
    ResolvedNbServiceInfo service,
  ) async {
    Connection(
      parentService: this,
      sendData: (data) => _sendData(service.device.deviceId, data),
      receiveData: service.receivedData.stream,
      disconnect: () async => await _nearbyService.disconnectPeer(
        deviceID: service.device.deviceId,
      ),
      serviceInfo: service,
    );

    _serviceInfos[service.device.deviceId] = service;
  }

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  final _isInitialized = Completer<void>();
  bool _isAdvertizing = false;
  bool _isDiscovering = false;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _receiveDataSubscription;
  var _connectedDevices = <Device>[];
  var _allDevices = <Device>[];
  final _serviceInfos = <String, ResolvedNbServiceInfo>{};

  Iterable<String> get _allDeviceIds => _allDevices.map((e) => e.deviceId);
  Iterable<String> get _connectedDeviceIds => _connectedDevices.map(
        (e) => e.deviceId,
      );

  late NearbyService _nearbyService;

  void _initNearby() async {
    _nearbyService = _d.newNearbyService();
    await _nearbyService.init(
      serviceType: 'mobile_network_evaluator_measure_nearby',
      deviceName: role == EndpointRole.advertizer ? 'Advertizer' : 'Scanner',
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          _isInitialized.complete();
        }
      },
    );
  }

  // ...........................................................................
  ResolvedNbServiceInfo _serviceInfo(String deviceId) {
    assert(_serviceInfos.containsKey(deviceId));
    return _serviceInfos[deviceId]!;
  }

  // ...........................................................................
  Future<void> get _startBrowsingForPeers async {
    await _nearbyService.startBrowsingForPeers();
    _discoverySubscription =
        _nearbyService.stateChangedSubscription(callback: _updateDevices);
  }

  // ...........................................................................
  void _updateDevices(List<Device> devices) {
    _handleDiscoveredDevices(devices);
    _handleConnectedDevices(devices);
    _handleDisconnectedDevices(devices);
    _handleDisappearedDevices(devices);

    _allDevices = [...devices];
    _connectedDevices =
        devices.where((d) => d.state == SessionState.connected).toList();
  }

  // ...........................................................................
  void _handleDiscoveredDevices(List<Device> devices) {
    final newDevices = devices.where(
      (device) => !_allDeviceIds.contains(device.deviceId),
    );

    // Invite all discovered devices
    for (var device in newDevices) {
      assert(device.state == SessionState.notConnected);
      _nearbyService.invitePeer(
        deviceID: device.deviceId,
        deviceName: device.deviceName,
      );
    }
  }

  // ...........................................................................
  void _handleConnectedDevices(List<Device> devices) {
    final connectdDevices = devices.where(
      (d) => d.state == SessionState.connected,
    );

    final newConnectedDevices = connectdDevices.where(
      (element) => !_connectedDeviceIds.contains(element.deviceId),
    );

    for (final device in newConnectedDevices) {
      onDiscoverService(ResolvedNbServiceInfo(device));
    }
  }

  // ...........................................................................
  void _handleDisconnectedDevices(List<Device> devices) {
    final disconnectedDevices = devices.where(
      (element) => element.state == SessionState.notConnected,
    );

    final disconnectedDeviceIds = disconnectedDevices.map((e) => e.deviceId);

    final newDisconnectedDevices = _connectedDevices.where(
      (d) => disconnectedDeviceIds.contains(d.deviceId),
    );

    for (var device in newDisconnectedDevices) {
      _disconnectDevice(device);
    }
  }

  // ...........................................................................
  void _handleDisappearedDevices(List<Device> devices) {
    final deviceIds = devices.map((e) => e.deviceId);
    final disappearedDevices = _connectedDevices.where(
      (d) => !deviceIds.contains(d.deviceId),
    );

    for (var device in disappearedDevices) {
      _disconnectDevice(device);
    }
  }

  // ...........................................................................
  void _disconnectDevice(Device device) {
    final serviceInfo = _serviceInfos[device.deviceId]!;
    final connection = connectionForService(serviceInfo)!;
    connection.disconnect();
    _serviceInfos.remove(device.deviceId);
  }

  // ...........................................................................
  Future<void> get _startListeningForData async {
    _receiveDataSubscription =
        _nearbyService.dataReceivedSubscription(callback: (data) {
      final deviceId = data['deviceID'] as String;
      final resolvedServiceInfo = _serviceInfo(deviceId);
      final messageString = data['message'];
      final messageBinary = base64Decode(messageString);
      resolvedServiceInfo.receivedData.add(messageBinary);
    });

    _dispose.add(() => _receiveDataSubscription?.cancel());
  }

  // ...........................................................................
  Future<void> _sendData(String deviceId, Uint8List data) async {
    final base64Data = base64Encode(data);
    await _nearbyService.sendMessage(deviceId, base64Data);
  }
}
