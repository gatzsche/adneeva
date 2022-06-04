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

import 'com/shared/adHoc_service.dart';
import 'com/shared/commands.dart';
import 'com/shared/network_service.dart';
import 'com/tcp/bonjour_service.dart';
import 'com/tcp/mocks/mock_network_interface.dart';
import 'measure/measure.dart';
import 'measure/nearby/measure_nb.dart';
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
    await _remoteControlService.advertizer.firstConnection;
    await _remoteControlService.scanner.firstConnection;
  }

  final mode = GgValue<MeasurementMode>(seed: MeasurementMode.tcp);
  final role = GgValue<EndpointRole>(seed: EndpointRole.advertizer);

  // ...........................................................................
  Measure? get measure => _measure;
  Measure? _measure;

  // ...........................................................................
  Future<void> waitForConnections() async {
    await waitUntilConnected;
    _listenForCommands();
    _syncModeChanges();
  }

  // ...........................................................................
  Future<void> startMeasurements() async {
    role.value = EndpointRole.advertizer;
    _updateModeAtOtherSide();
    await _startMeasurements();
  }

  // ...........................................................................
  Future<void> _startMeasurements() async {
    if (_measure?.isMeasuring.value == true) {
      return;
    }

    _startMeasurementOnOtherSide();
    _initMeasurement();
    await _measure!.connect();
    await _measure!.measure();

    await stopMeasurements();
  }

  // ...........................................................................
  Future<void> stopMeasurements() async {
    if (_measure == null) {
      return;
    }
    _measurementResult.value = _measure!.measurementResults.value;
    _measure!.disconnect();
    _measure!.dispose();
    _measure = null;
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
  AdHocService<BonjourService> get remoteControlService =>
      _remoteControlService;

  // ...........................................................................
  @visibleForTesting
  final int port = randomPort();

  // ######################
  // Test
  // ######################

  // ...........................................................................
  static void fakeConnect(Application appA, Application appB) {
    NetworkService.fakeConnect<BonsoirService>(
      appA.remoteControlService.advertizer,
      appB.remoteControlService.scanner,
    );

    NetworkService.fakeConnect<BonsoirService>(
      appB.remoteControlService.advertizer,
      appA.remoteControlService.scanner,
    );

    appA.waitForConnections();
    appB.waitForConnections();
  }

  // ######################
  // Private
  // ######################

  final _isInitialized = Completer();

  final List<Function()> _dispose = [];

  // ...........................................................................
  GgValueStream<bool> get isConnected =>
      remoteControlService.service(role.value).connectedEndpoints.map(
            (p0) => p0.isNotEmpty,
          );

  // ...........................................................................
  final _isMeasuring = GgValue<bool>(seed: false);

  // ...........................................................................
  Future<void> _init() async {
    await _initRemoteControlService();
    _isInitialized.complete();
  }

  // ...........................................................................
  late AdHocService<BonjourService> _remoteControlService;
  Future<void> _initRemoteControlService() async {
    final info = BonsoirService(
      name: 'Adneeva $port',
      port: port,
      type: '_adneeva-rc._tcp',
    );

    final advertizer = BonjourService(
      name: name,
      role: EndpointRole.advertizer,
      service: info,
      log: log,
    );

    final scanner = BonjourService(
      name: name,
      role: EndpointRole.scanner,
      service: info,
      log: log,
    );

    _remoteControlService = AdHocService<BonjourService>(
      advertizer: advertizer,
      scanner: scanner,
    );

    _remoteControlService.start();
    _dispose.add(_remoteControlService.dispose);
  }

  // ...........................................................................
  void _sendCommand(Command command) {
    _remoteControlService.advertizer.connectedEndpoints.value.first.sendString(
      '${command.toJsonString()}\n',
    );
  }

  // ...........................................................................
  void _listenForCommands() {
    _remoteControlService.scanner.connectedEndpoints.value.first.receiveData
        .listen(
      (uint8List) {
        // Only scanners receive commands currently
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
  void _syncModeChanges() {
    final s = mode.stream.listen(
      (value) => _updateModeAtOtherSide(),
    );

    _dispose.add(s.cancel);
  }

  // ...........................................................................
  void _updateModeAtOtherSide() {
    // if (role.value == EndpointRole.advertizer) {
    _sendCommand(
      EndpointRoleCmd(
        mode: mode.value,
        role: EndpointRole.scanner,
      ),
    );
    // }
  }

  // ...........................................................................
  StreamSubscription? _measureStreamSubscription;
  void _initMeasurement() {
    if (_measure != null) {
      return;
    }

    log?.call('Init measurement');
    _measureStreamSubscription?.cancel();
    _measureStreamSubscription?.cancel();

    final newMeasure = mode.value == MeasurementMode.tcp
        ? MeasureTcp.new
        : mode.value == MeasurementMode.nearby
            ? MeasureNb.new
            : MeasureTcp.new;

    _measure = newMeasure(role: role.value, log: log);

    _measureStreamSubscription = _measure!.isMeasuring.listen(
      (value) => _isMeasuring.value = value,
      // coverage:ignore-start
      onDone: () => _isMeasuring.value = false,
      onError: (_) => _isMeasuring.value = false,
      // coverage:ignore-end
    );
    _dispose.add(_measureStreamSubscription!.cancel);
  }

  // ...........................................................................
  void _startMeasurementOnOtherSide() {
    if (role.value == EndpointRole.advertizer) {
      _sendCommand(StartMeasurementCmd());
    }
  }

  // ...........................................................................
  void _stopMeasurementOnOtherSide() {
    if (role.value == EndpointRole.advertizer) {
      _sendCommand(StopMeasurementCmd());
    }
  }
}

// #############################################################################
Application exampleApplication({String name = 'Application'}) {
  return Application(name: name);
}
