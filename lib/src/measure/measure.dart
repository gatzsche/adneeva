// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';

import '../com/fake/fake_service.dart';
import '../com/shared/network_service.dart';
import 'types.dart';

class MeasureLogMessages {
  static const startMeasurementAsMaster = 'Start measurement as master';
  static const stopMeasurementAsMaster = 'Stop measurement as master';
  static const startMeasurementAsSlave = 'Start measurement as slave';
  static const stopMeasurementAsSlave = 'Stop measurement as slave';
}

class Measure {
  Measure({
    required this.role,
    this.log,
    required this.networkService,
  }) {
    _initIsMeasuring();
  }

  // ...........................................................................
  @mustCallSuper
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  final Log? log;
  final NetworkService networkService;

  // ...........................................................................
  final MeasurmentRole role;

  // ...........................................................................
  @mustCallSuper
  Future<void> start() =>
      role == MeasurmentRole.master ? startMaster() : startSlave();

  // ...........................................................................
  @mustCallSuper
  Future<void> stop() =>
      role == MeasurmentRole.master ? stopMaster() : stopSlave();

  // ######################
  // Master
  // ######################

  // ...........................................................................
  @mustCallSuper
  Future<void> startMaster() async {
    log?.call(MeasureLogMessages.startMeasurementAsMaster);
    // Wait for the first connection
    final firstConnection = await networkService.firstConnection;

    // Once connected initialize the measurement controller
    // Run measurements
    // Make results available
  }

  // ...........................................................................
  @mustCallSuper
  Future<void> stopMaster() async {
    log?.call(MeasureLogMessages.stopMeasurementAsMaster);
  }

  // ######################
  // Slave
  // ######################

  // ...........................................................................
  Future<void> startSlave() async {
    log?.call(MeasureLogMessages.startMeasurementAsSlave);
    // Wait for the first connection
    // await networkService.waitForFirstConnection;

    // Listen to incoming data
    // Send acknowledgement, once data has been received
  }

  // ...........................................................................
  Future<void> stopSlave() async {
    log?.call(MeasureLogMessages.stopMeasurementAsSlave);
  }

  // ...........................................................................
  final isMeasuring = GgValue<bool>(seed: false);
  void _initIsMeasuring() {
    _dispose.add(isMeasuring.dispose);
  }

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
}

// #############################################################################

Measure exampleMeasureMaster({Log? log}) {
  return Measure(
    role: MeasurmentRole.master,
    log: log,
    networkService: FakeService.master,
  );
}

Measure exampleMeasureSlave({Log? log}) {
  return Measure(
    role: MeasurmentRole.slave,
    log: log,
    networkService: FakeService.slave,
  );
}
//