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
  Application({required this.name, this.log}) {
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
  final Log? log;

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
  Future<void> waitForConnections() async {
    log?.call('Wait for connections');
    await waitUntilConnected;
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
    await stopMeasurements();
  }

  // ...........................................................................
  Future<void> startMeasurements() async {
    role.value = EndpointRole.master;
    _updateModeAtOtherSide();
    await _startMeasurements();
  }

  // ...........................................................................
  Future<void> stopMeasurements() async {
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
  static void fakeConnectMeasurementCore(Application appA, Application appB) {
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
  final _isMeasuring = GgValue<bool>(seed: false);

  // ...........................................................................
  Future<void> _init() async {
    log?.call('Init');

    await _initRemoteControlService();
    _initMeasurement();
    _isInitialized.complete();
  }

  // ...........................................................................
  late BipolarService<BonjourService> _remoteControlService;
  Future<void> _initRemoteControlService() async {
    log?.call('Init remote control service');

    final info = BonsoirService(
      name: 'Mobile Network Evaluator $port',
      port: port,
      type: '_mobile_network_evaluator_remote_control._tcp',
    );

    final master = BonjourService(
      name: name,
      role: EndpointRole.master,
      service: info,
      log: log,
    );

    final slave = BonjourService(
      name: name,
      role: EndpointRole.slave,
      service: info,
      log: log,
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
      '${command.toJsonString()}\n',
    );
  }

  // ...........................................................................
  void _listenForCommands() {
    _remoteControlService.slave.connections.value.first.receiveData.listen(
      (uint8List) {
        // Only slaves receive commands currently
        final string = String.fromCharCodes(uint8List);
        final commands = string.split('\n').where(
              (e) => e.isNotEmpty,
            );
        for (final commandStr in commands) {
          final command = json.decode(commandStr);

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
        }
      },
    );
  }

  // ...........................................................................
  void _updateModeAtOtherSide() {
    if (role.value == EndpointRole.master) {
      _sendCommand(
        EndpointRoleCmd(
          mode: mode.value,
          role: EndpointRole.slave,
        ),
      );
    }
  }

  // ...........................................................................
  StreamSubscription? _measureStreamSubscription;
  StreamSubscription? _measurementResultSubscription;
  void _initMeasurement() {
    log?.call('Init measurement');
    _measureStreamSubscription?.cancel();
    _measureStreamSubscription?.cancel();
    _measure = MeasureTcp(role: role.value, log: log);

    _measureStreamSubscription = _measure.isMeasuring.listen(
      (value) => _isMeasuring.value = value,
      // coverage:ignore-start
      onDone: () => _isMeasuring.value = false,
      onError: (_) => _isMeasuring.value = false,
      // coverage:ignore-end
    );
    _dispose.add(_measureStreamSubscription!.cancel);

    _measurementResultSubscription = _measure.measurementResults.listen(
      (event) => _measurementResult.value = event,
    );
    _dispose.add(_measurementResultSubscription!.cancel);
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
