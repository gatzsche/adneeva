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

  final measurmentMode = GgValue<MeasurementMode>(seed: MeasurementMode.idle);
  final role = GgValue<EndpointRole>(seed: EndpointRole.master);

  // ...........................................................................
  Measure? get measure => _measure;
  Measure? _measure;

  // ...........................................................................
  void waitForConnections() async {
    await waitUntilConnected;
    _listenToEndpointRole();
    _listenForCommands();
  }

  // ...........................................................................
  Future<void> startMeasurements() async {
    if (_measure?.isMeasuring.value == true) {
      return;
    }
    _startMeasurementOnOtherSide();
    _initMeasurement();
    await _measure!.connect();
    await _measure!.measure();
  }

  // ...........................................................................
  void stopMeasurements() async {
    _measure?.disconnect();
    _stopMeasurementOnOtherSide();
  }

  // ...........................................................................
  List<String>? get measurementResults => _measure?.measurmentResults;

  // ...........................................................................
  bool get isMeasuring => _measure?.isMeasuring.value ?? false;

  // ######################
  // Test
  // ######################

  @visibleForTesting
  BipolarService<BonjourService> get remoteControlService =>
      _remoteControlService;

  @visibleForTesting
  final int port = randomPort();

  // ######################
  // Private
  // ######################

  final _isInitialized = Completer();

  final List<Function()> _dispose = [];

  bool get isConnected =>
      remoteControlService.service(role.value).connections.value.isNotEmpty;

  // ...........................................................................
  void _init() async {
    await _initRemoteControlService();
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
          measurmentMode.value = cmd.mode;
        } else if (id == 'StartMeasurementCmd') {
          startMeasurements();
        } else if (id == 'StopMeasurementCmd') {
          stopMeasurements();
        }
      },
    );
  }

  // ...........................................................................
  void _listenToEndpointRole() {
    StreamGroup.merge([measurmentMode.stream, role.stream]).listen(
      (value) {
        if (role.value == EndpointRole.master) {
          _sendCommand(EndpointRoleCmd(
            mode: measurmentMode.value,
            role: EndpointRole.slave,
          ));
        }
      },
    );
  }

  // ...........................................................................
  void _initMeasurement() {
    _measure = MeasureTcp(role: role.value);
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
