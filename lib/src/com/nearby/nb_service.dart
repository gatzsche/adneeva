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
import '../shared/endpoint.dart';
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
  NbServiceInfo({
    required this.type,
    required this.deviceId,
  }) {
    _checkType();
  }
  final String type;
  final String deviceId;

  void _checkType() {
    assert(type.length <= 15);
    assert('-'.allMatches(type).length <= 1);
    assert(!type.contains('_'));
  }
}

class ResolvedNbServiceInfo extends NbServiceInfo {
  ResolvedNbServiceInfo({
    required super.type,
    required super.deviceId,
  });
  final receivedData = StreamController<Uint8List>.broadcast();
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
    log?.call('Create NBService with role {$role}');
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
  bool isSameService(NbServiceInfo a, NbServiceInfo b) {
    if (a is ResolvedNbServiceInfo && b is ResolvedNbServiceInfo) {
      return a.deviceId == b.deviceId;
    } else {
      return a == b;
    }
  }

  // ######################
  // Advertizer
  // ######################

  // ...........................................................................
  @override
  Future<void> startAdvertizing() async {
    _initNearby();
    await _startAdvertizing;
    await _startScanningForPeers;
  }

  // ...........................................................................
  Future<void> get _startAdvertizing async {
    log?.call('Start advertizing');

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
    await _stopAdvertizing;
    await _stopScanning;
  }

  // ...........................................................................
  Future<void> get _stopAdvertizing async {
    log?.call('Stop advertizing');
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
  // Scanner
  // ######################

  // ...........................................................................
  @override
  Future<void> startScanning() async {
    _initNearby();
    await _startScanning();
    await _startAdvertizing;
  }

  // ...........................................................................
  Future<void> _startScanning() async {
    log?.call('Stop scanning');
    if (_isDiscovering) {
      return;
    }
    _isDiscovering = true;

    await _isInitialized.future;

    await _startScanningForPeers;
    await _startListeningForData;
    _dispose.add(() => _discoverySubscription?.cancel);
  }

  // ...........................................................................
  @override
  Future<void> stopScanning() async {
    await _stopScanning;
  }

  // ...........................................................................
  Future<void> get _stopScanning async {
    log?.call('Stop scanning');
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
    Endpoint<NbServiceInfo>(
      parentService: this,
      sendData: (data) => _sendData(service.deviceId, data),
      receiveData: service.receivedData.stream,
      disconnect: () async => await _nearbyService.disconnectPeer(
        deviceID: service.deviceId,
      ),
      serviceInfo: service,
    );

    _serviceInfos[service.deviceId] = service;
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
    log?.call('Init Nearby');
    _nearbyService = _d.newNearbyService();

    await _nearbyService.init(
      serviceType: service.type,
      deviceName: service.deviceId,
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
  Future<void> get _startScanningForPeers async {
    log?.call('Start scanning for peers');
    await _nearbyService.startBrowsingForPeers();
    _discoverySubscription =
        _nearbyService.stateChangedSubscription(callback: _updateDevices);
  }

  // ...........................................................................
  void _updateDevices(List<Device> devices) {
    log?.call('Update devices');
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
    // Only scanners are connecting discovered devices
    // if (role == EndpointRole.advertizer) {
    //   return;
    // }

    final newDevices = devices.where(
      (device) => !_allDeviceIds.contains(device.deviceId),
    );

    // Invite all discovered devices
    for (var device in newDevices) {
      bool isZombi = device.state != SessionState.notConnected;
      if (isZombi) {
        continue;
      }
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
      onDiscoverService(ResolvedNbServiceInfo(
        deviceId: device.deviceId,
        type: mockServiceInfo.type,
      ));
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
    final connection = endpointForService(serviceInfo)!;
    connection.disconnect();
    _serviceInfos.remove(device.deviceId);
  }

  // ...........................................................................
  Future<void> get _startListeningForData async {
    log?.call('Start listening for data');
    _receiveDataSubscription =
        _nearbyService.dataReceivedSubscription(callback: (data) {
      final deviceId = data['deviceId'] as String;

      // Workaround: Currently we are not able to assign the incoming data
      // to one of the connections. Thus we take the first connection.
      // final resolvedServiceInfo = _serviceInfo(deviceId);
      final resolvedServiceInfo = _serviceInfos.values.first;
      final messageString = data['message'];
      final messageBinary = base64Decode(messageString);
      resolvedServiceInfo.receivedData.add(messageBinary);
    });

    _dispose.add(() => _receiveDataSubscription?.cancel());
  }

  // ...........................................................................
  Future<void> _sendData(String deviceId, Uint8List data) async {
    log?.call('Send data');
    final base64Data = base64Encode(data);
    await _nearbyService.sendMessage(deviceId, base64Data);
  }
}
