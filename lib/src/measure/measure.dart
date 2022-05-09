// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';

import '../com/fake/fake_service.dart';
import '../com/shared/connection.dart';
import '../com/shared/network_service.dart';
import 'data_recorder.dart';
import 'types.dart';

class MeasureLogMessages {
  static String start(EndpointRole role) => 'Start measurement as $role';
  static String measure(EndpointRole role) => 'Measure as $role';
  static String stop(EndpointRole role) => 'Stop measurement as $role';
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
  final EndpointRole role;

  // ...........................................................................
  Future<void> connect() async {
    if (_connection != null) {
      return;
    }
    _logStart();
    await _connect();
  }

  // ...........................................................................
  Future<void> measure() async {
    assert(!_isMeasuring.value);
    assert(_connection != null);

    _logMeasure();
    _isMeasuring.value = true;

    _dataRecorder = DataRecorder(
      connection: _connection!,
      role: role,
      log: log,
    );

    await _dataRecorder!.record();

    if (_dataRecorder?.resultCsv != null) {
      _measurementResults.value = [
        ..._measurementResults.value,
        _dataRecorder!.resultCsv!
      ];
    }
    _isMeasuring.value = false;
  }

  // ...........................................................................
  Future<void> disconnect() async {
    assert(_connection != null);

    _logStop();

    _dataRecorder?.stop();
    _dataRecorder = null;

    await _disconnect();
    _connection = null;
  }

  // ...........................................................................
  GgValueStream<List<String>> get measurmentResults =>
      _measurementResults.stream;

  // ...........................................................................
  GgValueStream<bool> get isMeasuring => _isMeasuring.stream;

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  final _measurementResults = GgValue<List<String>>(seed: []);
  final _isMeasuring = GgValue<bool>(seed: false);
  void _initIsMeasuring() {
    _dispose.add(_isMeasuring.dispose);
  }

  Connection? _connection;

  // ...........................................................................
  DataRecorder? _dataRecorder;

  // ...........................................................................
  Future<void> _connect() async {
    await networkService.start();
    final connection = await networkService.firstConnection;
    _connection = connection;
  }

  // ...........................................................................
  Future<void> _disconnect() async {
    await networkService.stop();
  }

  // ...........................................................................
  void _logStart() => log?.call(MeasureLogMessages.start(role));
  void _logStop() => log?.call(MeasureLogMessages.stop(role));
  void _logMeasure() => log?.call(MeasureLogMessages.measure(role));
}

// #############################################################################

Measure exampleMeasureMaster({Log? log}) {
  return Measure(
    role: EndpointRole.master,
    log: log,
    networkService: FakeService.master,
  );
}

Measure exampleMeasureSlave({Log? log}) {
  return Measure(
    role: EndpointRole.slave,
    log: log,
    networkService: FakeService.slave,
  );
}
//
