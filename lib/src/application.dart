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

import 'com/shared/commands.dart';
import 'com/tcp/bonjour_service.dart';
import 'com/tcp/mocks/mock_network_interface.dart';
import 'measure/measure.dart';
import 'measure/tcp/measure_tcp.dart';
import 'measure/types.dart';
import 'utils/is_test.dart';
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
    _d = isTest ? MockApplicationDeps() : ApplicationDeps();
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
  Future<void> get waitUntilConnected => _remoteControlService.firstConnection;

  final measurmentMode = GgValue<MeasurmentMode>(seed: MeasurmentMode.idle);
  final measurmentRole = GgValue<MeasurmentRole>(seed: MeasurmentRole.master);

  // ...........................................................................
  Measure? _measure;

  // ...........................................................................
  void waitForConnections() async {
    await waitUntilConnected;
    _listenToMeasurmentMode();
    _listenForCommands();
  }

  // ...........................................................................
  Future<void> startMeasurements() async {
    if (_measure?.isMeasuring.value == true) {
      return;
    }
    isMeasuring.value = true;

    if (measurmentMode.value == MeasurmentMode.tcp) {
      _measure = MeasureTcp(role: MeasurmentRole.master);
    } else {
      throw UnimplementedError;
    }

    await _measure!.start();
  }

  // ...........................................................................
  Future<void> stopMeasurments() async {
    await _measure?.stop();
  }

  final isMeasuring = GgValue<bool>(seed: false);
  void _initIsMeasuring() {
    _dispose.add(isMeasuring.dispose);
  }

  // ######################
  // Test
  // ######################

  @visibleForTesting
  BonjourService get remoteControlService => _remoteControlService;

  @visibleForTesting
  final int port = randomPort();
  String get ip => _ipAddress;

  // ######################
  // Private
  // ######################

  late ApplicationDeps _d;
  final _isInitialized = Completer();

  final List<Function()> _dispose = [];

  late String _ipAddress;
  bool get isConnected => _remoteControlService.connections.value.isNotEmpty;

  // ...........................................................................
  Future<void> _initIpAddress() async {
    _ipAddress = '127.0.0.1';
    for (var interface in await _d.networkInterfaceList()) {
      for (var addr in interface.addresses) {
        _ipAddress = addr.address;
        break;
      }
    }
  }

  // ...........................................................................
  void _init() async {
    _initIsMeasuring();
    await _initIpAddress();
    await _initRemoteControl();
    _isInitialized.complete();
  }

  // ...........................................................................
  late BonjourService _remoteControlService;
  Future<void> _initRemoteControl() async {
    _remoteControlService = BonjourService(
      name: name,
      mode: NetworkServiceMode.masterAndSlave,
      service: BonsoirService(
        name: 'Mobile Network Evaluator',
        port: port,
        type: '_mobile_network_evaluator._tcp',
      ),
    );

    _remoteControlService.start();
    _dispose.add(_remoteControlService.dispose);
  }

  // ...........................................................................
  void _sendCommand(Command command) {
    _remoteControlService.connections.value.first.sendString(
      command.toJsonString(),
    );
  }

  // ...........................................................................
  void _listenForCommands() {
    _remoteControlService.connections.value.first.receiveData.listen(
      (uint8List) {
        final string = String.fromCharCodes(uint8List);
        final command = json.decode(string);

        if (command['id'] == 'MeasurmentModeCmd') {
          final cmd = MeasurmentModeCmd.fromJson(command);
          measurmentRole.value = cmd.role;
          measurmentMode.value = cmd.mode;
        }
      },
    );
  }

  // ...........................................................................
  void _listenToMeasurmentMode() {
    StreamGroup.merge([measurmentMode.stream, measurmentRole.stream]).listen(
      (value) {
        if (measurmentRole.value == MeasurmentRole.master) {
          _sendCommand(MeasurmentModeCmd(
            mode: measurmentMode.value,
            role: MeasurmentRole.slave,
          ));
        }
      },
    );
  }
}

// #############################################################################
Application exampleApplication({String name = 'Application'}) {
  return Application(name: name);
}
