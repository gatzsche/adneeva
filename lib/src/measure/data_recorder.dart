// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../com/shared/endpoint.dart';
import '../utils/is_test.dart';
import '../utils/utils.dart';
import 'types.dart';

class Messages {
  static const packetStart = 'PacketStart';
  static const packetEnd = 'PacketEnd';
  static const acknowledgment = 'Acknowledgement';
}

const _oneKb = 1024;
const _oneMb = _oneKb * _oneKb;
const _tenMb = 10 * _oneMb;

class DataRecorder {
  DataRecorder({
    required this.connection,
    required this.role,
    this.log,
    this.maxNumMeasurements = 2,
    this.packageSizes = const [_oneKb, _oneMb, _tenMb],
  }) {
    _initMeasurementCycles();
  }

  static Duration? delayMeasurements;

  // ...........................................................................
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  bool get isRunning => _isRunning;

  // ...........................................................................
  final Endpoint connection;
  final EndpointRole role;

  // ######################
  // Advertizer
  // ######################

  /// Listen to incoming acknowledgments and start next measurement cycle then

  final int maxNumMeasurements;
  final Log? log;
  final List<int> packageSizes;

  Stream<int> get measurementCycles => _measurementCycles.stream;

  // ...........................................................................
  Future<void> get _waitForAcknowledgement => connection.receiveData.firstWhere(
        (event) {
          return event.string.startsWith(Messages.acknowledgment);
        },
      );

  // ...........................................................................
  Future<void> record() async {
    if (role == EndpointRole.advertizer) {
      await _sendDataToScannerAndWaitForAcknowledgement();
    } else {
      await _listenToDataFromAdvertizerAndAcknowledge();
    }
  }

  // ...........................................................................
  StreamSubscription? _listenToDataFromAdvertizerSubscription;
  Completer? _listenToDataCompleter;
  int _receivedBytes = 0;
  Future<void> _listenToDataFromAdvertizerAndAcknowledge() {
    _listenToDataCompleter = Completer();

    _listenToDataFromAdvertizerSubscription = connection.receiveData.listen(
      (data) {
        final str = data.string;
        _receivedBytes += data.lengthInBytes;
        if (str.endsWith(Messages.packetEnd)) {
          log?.call('Acknowledging data of size $_receivedBytes');
          _receivedBytes = 0;
          connection.sendData(Messages.acknowledgment.uint8List);
        }
      },
    );

    _dispose.add(() => _listenToDataFromAdvertizerSubscription?.cancel);

    return _listenToDataCompleter!.future;
  }

  // ...........................................................................
  Future<void> _sendDataToScannerAndWaitForAcknowledgement() async {
    _stop = false;

    _isRunning = true;

    for (final packageSize in packageSizes) {
      _initResultArray(packageSize);

      log?.call('Measuring data for packageSize $packageSize');

      for (var iteration = 0; iteration < maxNumMeasurements; iteration++) {
        if (_stop) {
          log?.call('Stopping measurement');
          break;
        }

        _measurementCycles.add(iteration);
        _initBuffer(packageSize);
        _startTimeMeasurement();
        _sendDataToScanner();
        await _waitForAcknowledgement;
        _stopTimeMeasurement();
        _writeMeasuredTimes(packageSize);

        if (delayMeasurements != null) {
          await Future.delayed(delayMeasurements!);
        }
      }
    }

    _isRunning = false;

    if (!_stop) {
      log?.call('Exporting Measurement Results');
      await _exportMeasuredResults();
    }

    log?.call('Done.');
  }

  // ...........................................................................
  void stop() {
    _stop = true;
    _listenToDataFromAdvertizerSubscription?.cancel();
    _listenToDataFromAdvertizerSubscription = null;
    _listenToDataCompleter?.complete();
    _listenToDataCompleter = null;
  }

  // ...........................................................................
  String? get resultCsv {
    return _resultCsv;
  }

  // ...........................................................................
  Uint8List? _buffer;
  void _initBuffer(int packageSize) {
    final builder = BytesBuilder();
    final bufferStartMsg = Messages.packetStart.uint8List;
    final bufferEndMsg = Messages.packetEnd.uint8List;
    final fillBytes = packageSize - bufferStartMsg.length - bufferEndMsg.length;

    builder.add(bufferStartMsg);

    final payload = ''.padRight(fillBytes, ' ');
    builder.add(payload.uint8List);
    builder.add(bufferEndMsg);

    _buffer = builder.takeBytes();
  }

  // ...........................................................................
  void _startTimeMeasurement() {
    _stopWatch.reset();
    _stopWatch.start();
  }

  // ...........................................................................
  Future<void> _sendDataToScanner() async {
    log?.call('Sending buffer of size ${_buffer!.lengthInBytes}...');
    await connection.sendData(_buffer!);
  }

  // ...........................................................................
  void _stopTimeMeasurement() {
    _stopWatch.stop();
  }

  // ...........................................................................
  final Map<int, List<int>> _measurementResults = {};
  void _initResultArray(int packageSize) {
    _measurementResults[packageSize] = [];
  }

  // ...........................................................................
  void _writeMeasuredTimes(int packageSize) {
    final elapsedTime = _stopWatch.elapsed.inMicroseconds;
    _measurementResults[packageSize]!.add(elapsedTime);
  }

  // ...........................................................................
  String? _resultCsv;

  // ...........................................................................
  Future<void> _exportMeasuredResults() async {
    String csv = '';

    // table header
    /* csvContent += "Byte Size";
    csvContent += ",";
    for (var i = 0; i < maxNumMeasurements; i++) {
      csvContent += "${i + 1}";
      if (i < maxNumMeasurements - 1) {
        csvContent += ",";
      }
    }
    csvContent += "\n"; */

    // for each serial number,
    //   iterate the measurement results.
    //   i.e
    //   iterate each byte size of the measurement results
    //   get the measurement array for each byte size
    //   get the measurement out of the array

    //create csv table
    csv += 'Byte Sizes';
    csv += ',';
    for (var packageSize in packageSizes) {
      csv += '$packageSize';
      final isLast = packageSize == packageSizes.last;
      if (!isLast) {
        csv += ',';
      }
    }
    csv += '\n';

    for (var i = 0; i < maxNumMeasurements; i++) {
      var numOfIterations = i + 1;

      csv += '$numOfIterations';
      csv += ',';
      log?.call('Num: $numOfIterations');

      for (var packetSize in packageSizes) {
        final size = packetSize;
        final times = _measurementResults[packetSize]![i];
        final isLast = packetSize == packageSizes.last;

        csv += '$times';
        if (!isLast) {
          csv += ',';
        }

        log?.call('$size: $times');
      }

      final isLastRow = i == maxNumMeasurements - 1;
      if (!isLastRow) {
        csv += '\n';
      }
    }

    if (!isTest) {
      // coverage:ignore-start
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('measurements.csv', csv);
      // coverage:ignore-end
    }

    _resultCsv = csv;

    // const path = '/Users/ajibade/Desktop/measurement_result.csv';
    // var myFile = File(path);
    // if (myFile.existsSync()) {
    //   myFile.deleteSync();
    //   myFile = File(path);
    // }
    // myFile.writeAsStringSync(_resultCsv);
  }

  // ...........................................................................
  final _stopWatch = Stopwatch();

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];

  bool _stop = false;
  bool _isRunning = false;
  final _measurementCycles = StreamController<int>();
  void _initMeasurementCycles() {
    _dispose.add(_measurementCycles.close);
  }
}

// #############################################################################
DataRecorder exampleAdvertizerDataRecorder({Endpoint? connection}) =>
    DataRecorder(
      connection: connection ?? exampleConnection(),
      role: EndpointRole.advertizer,
    );

// #############################################################################
DataRecorder exampleScannerDataRecorder({Endpoint? connection}) => DataRecorder(
      connection: connection ?? exampleConnection(),
      role: EndpointRole.scanner,
    );
