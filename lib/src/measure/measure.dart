// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';

import '../com/fake/fake_service.dart';
import '../com/shared/endpoint.dart';
import '../com/shared/network_service.dart';
import 'data_recorder.dart';
import 'types.dart';

class MeasureLogMessages {
  static String connect(EndpointRole role) => 'Connecting';
  static String connected(EndpointRole role) => 'Connected';
  static String measure(EndpointRole role) => 'Measuring';
  static String disconnect(EndpointRole role) => 'Disconnecting';
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
    _logConnect();
    await _connect();
    _logConnected();
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
  bool _isDisconnecting = false;
  Future<void> disconnect() async {
    if (_isDisconnecting || _connection == null) {
      return;
    }
    _isDisconnecting = true;

    _logDisconnect();

    _dataRecorder?.stop();
    _dataRecorder = null;
    _isMeasuring.value = false;

    await _disconnect();
    _connection = null;
    _isDisconnecting = false;
  }

  // ...........................................................................
  GgValueStream<List<String>> get measurementResults =>
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

  Endpoint? _connection;

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
  void _logConnect() => log?.call(MeasureLogMessages.connect(role));
  void _logConnected() => log?.call(MeasureLogMessages.connected(role));
  void _logDisconnect() => log?.call(MeasureLogMessages.disconnect(role));
  void _logMeasure() => log?.call(MeasureLogMessages.measure(role));
}

// #############################################################################

Measure exampleMeasureAdvertizer({Log? log}) {
  return Measure(
    role: EndpointRole.advertizer,
    log: log,
    networkService: FakeService.advertizer,
  );
}

Measure exampleMeasureScanner({Log? log}) {
  return Measure(
    role: EndpointRole.scanner,
    log: log,
    networkService: FakeService.scanner,
  );
}
//
