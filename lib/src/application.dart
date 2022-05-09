// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';
import 'package:async/async.dart';

import 'com/shared/bipolar_service.dart';
import 'com/shared/commands.dart';
import 'com/shared/network_service.dart';
import 'com/tcp/bonjour_service.dart';
import 'com/tcp/mocks/mock_network_interface.dart';
import 'measure/measure.dart';
import 'measure/tcp/measure_tcp.dart';
import 'measure/types.dart';
import 'utils/utils.dart';

// #############################################################################
class ApplicationDeps {
  final networkInterfaceList = NetworkInterface.list;
}

class MockApplicationDeps implements ApplicationDeps {
  @override
  final networkInterfaceList = MockNetworkInterface.list;
}

// #############################################################################
class Application {
  Application({required this.name}) {
    _init();
  }

  // ...........................................................................
  void dispose() {
    for (final d in _dispose) {
      d();
    }
  }

  // ...........................................................................
  final String name;

  // ...........................................................................
  Future<void> get waitUntilConnected async {
    await _remoteControlService.master.firstConnection;
    await _remoteControlService.slave.firstConnection;
  }

  final mode = GgValue<MeasurementMode>(seed: MeasurementMode.tcp);
  final role = GgValue<EndpointRole>(seed: EndpointRole.master);

  // ...........................................................................
  Measure get measure => _measure;
  late Measure _measure;

  // ...........................................................................
  void waitForConnections() async {
    await waitUntilConnected;
    _listenToEndpointRole();
    _listenForCommands();
  }

  // ...........................................................................
  Future<void> _startMeasurements() async {
    if (_measure.isMeasuring.value == true) {
      return;
    }
    _startMeasurementOnOtherSide();
    _initMeasurement();
    await _measure.connect();
    await _measure.measure();
  }

  // ...........................................................................
  Future<void> startMeasurements() async {
    role.value = EndpointRole.master;
    await _startMeasurements();
  }

  // ...........................................................................
  void stopMeasurements() async {
    _measure.disconnect();
    _stopMeasurementOnOtherSide();
  }

  // ...........................................................................
  GgValueStream<bool> get isMeasuring => _isMeasuring.stream;

  // ...........................................................................
  GgValueStream<List<String>> get measurementResults =>
      _measurementResult.stream;

  final _measurementResult = GgValue<List<String>>(seed: []);

  // ...........................................................................
  @visibleForTesting
  BipolarService<BonjourService> get remoteControlService =>
      _remoteControlService;

  // ...........................................................................
  @visibleForTesting
  final int port = randomPort();

  // ######################
  // Test
  // ######################

  // ...........................................................................
  static void fakeConnect(Application appA, Application appB) {
    NetworkService.fakeConnect(
      appA.remoteControlService.master,
      appB.remoteControlService.slave,
    );

    NetworkService.fakeConnect(
      appB.remoteControlService.master,
      appA.remoteControlService.slave,
    );

    appA.waitForConnections();
    appB.waitForConnections();
  }

  // ...........................................................................
  static void fakeConnectMeasurmentCore(Application appA, Application appB) {
    NetworkService.fakeConnect(
      appA.measure.networkService,
      appB.measure.networkService,
    );
  }

  // ######################
  // Private
  // ######################

  final _isInitialized = Completer();

  final List<Function()> _dispose = [];

  // ...........................................................................
  GgValueStream<bool> get isConnected =>
      remoteControlService.service(role.value).connections.map(
            (p0) => p0.isNotEmpty,
          );

  // ...........................................................................
  void _initIsConnected() {
    final s = isConnected.listen(
      (isConnected) {
        if (isConnected) {
          _updateModeAtOtherSide();
        }
      },
    );
    _dispose.add(s.cancel);
  }

  // ...........................................................................
  final _isMeasuring = GgValue<bool>(seed: false);

  // ...........................................................................
  void _init() async {
    await _initRemoteControlService();
    _initMeasurement();
    _initIsConnected();
    _isInitialized.complete();
  }

  // ...........................................................................
  late BipolarService<BonjourService> _remoteControlService;
  Future<void> _initRemoteControlService() async {
    final info = BonsoirService(
      name: 'Mobile Network Evaluator',
      port: port,
      type: '_mobile_network_evaluator._tcp',
    );

    final master = BonjourService(
      name: name,
      mode: EndpointRole.master,
      service: info,
    );

    final slave = BonjourService(
      name: name,
      mode: EndpointRole.slave,
      service: info,
    );

    _remoteControlService = BipolarService<BonjourService>(
      master: master,
      slave: slave,
    );

    _remoteControlService.start();
    _dispose.add(_remoteControlService.dispose);
  }

  // ...........................................................................
  void _sendCommand(Command command) {
    _remoteControlService.master.connections.value.first.sendString(
      command.toJsonString(),
    );
  }

  // ...........................................................................
  void _listenForCommands() {
    _remoteControlService.slave.connections.value.first.receiveData.listen(
      (uint8List) {
        // Currently only master sends remote control commands

        final string = String.fromCharCodes(uint8List);
        final command = json.decode(string);

        final id = command['id'];

        if (id == 'EndpointRoleCmd') {
          final cmd = EndpointRoleCmd.fromJson(command);
          role.value = cmd.role;
          mode.value = cmd.mode;
        } else if (id == 'StartMeasurementCmd') {
          _startMeasurements();
        } else if (id == 'StopMeasurementCmd') {
          stopMeasurements();
        }
      },
    );
  }

  // ...........................................................................
  void _listenToEndpointRole() {
    StreamGroup.merge([mode.stream, role.stream]).listen(
      (value) {
        _updateModeAtOtherSide();
      },
    );
  }

  // ...........................................................................
  void _updateModeAtOtherSide() {
    if (role.value == EndpointRole.master) {
      _sendCommand(EndpointRoleCmd(
        mode: mode.value,
        role: EndpointRole.slave,
      ));
    }
  }

  // ...........................................................................
  StreamSubscription? _measureStreamSubscription;
  StreamSubscription? _measurmentResultSubscription;
  void _initMeasurement() {
    _measureStreamSubscription?.cancel();
    _measureStreamSubscription?.cancel();
    _measure = MeasureTcp(role: role.value);

    _measureStreamSubscription = _measure.isMeasuring.listen(
      (value) => _isMeasuring.value = value,
      // coverage:ignore-start
      onDone: () => _isMeasuring.value = false,
      onError: (_) => _isMeasuring.value = false,
      // coverage:ignore-end
    );
    _dispose.add(_measureStreamSubscription!.cancel);

    _measurmentResultSubscription = _measure.measurmentResults.listen(
      (event) => _measurementResult.value = event,
    );
    _dispose.add(_measurmentResultSubscription!.cancel);
  }

  // ...........................................................................
  void _startMeasurementOnOtherSide() {
    if (role.value == EndpointRole.master) {
      _sendCommand(StartMeasurementCmd());
    }
  }

  // ...........................................................................
  void _stopMeasurementOnOtherSide() {
    if (role.value == EndpointRole.master) {
      _sendCommand(StopMeasurementCmd());
    }
  }
}

// #############################################################################
Application exampleApplication({String name = 'Application'}) {
  return Application(name: name);
}
