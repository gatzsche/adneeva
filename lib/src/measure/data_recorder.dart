// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../com/shared/connection.dart';
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
    this.maxNumMeasurements = 10,
    this.packageSizes = const [_oneKb, _oneMb, _tenMb],
  }) {
    if (role == MeasurmentRole.slave) {
      _initSlave();
    }
  }

  // ...........................................................................
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  final Connection connection;
  final MeasurmentRole role;

  // ######################
  // Slave
  // ######################

  /// Listen to incoming data packets and send acknowledgement
  void _initSlave() {
    final s = connection.receiveData.listen(
      (data) {
        if (data.string == Messages.packetEnd) {
          connection.sendData(Messages.acknowledgment.uint8List);
        }
      },
    );

    _dispose.add(s.cancel);
  }

  // ######################
  // Master
  // ######################

  /// Listen to incoming acknowledgments and start next measurement cycle then

  final int maxNumMeasurements;
  final Log? log;
  final List<int> packageSizes;

  // ...........................................................................
  Future<void> get _waitForAcknowledgement async {
    await connection.receiveData.firstWhere((event) {
      return event.string.startsWith(Messages.acknowledgment);
    });
  }

  // ...........................................................................
  void run() async {
    if (role == MeasurmentRole.slave) {
      return;
    }

    for (final packageSize in packageSizes) {
      _initResultArray(packageSize);

      log?.call('Measuring data for packageSize $packageSize ...');

      for (var iteration = 0; iteration < maxNumMeasurements; iteration++) {
        _initBuffer(packageSize);
        _startTimeMeasurement();
        await _sendDataToServer();
        await _waitForAcknowledgement;
        _stopTimeMeasurement();
        _writeMeasuredTimes(packageSize);
      }
    }

    log?.call('Exporting Measurement Results');
    _exportMeasuredResults();
    log?.call('Done.');
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
    builder.add(ByteData(fillBytes).buffer.asUint8List());
    builder.add(bufferEndMsg);

    _buffer = builder.takeBytes();
  }

  // ...........................................................................
  void _startTimeMeasurement() {
    _stopWatch.reset();
    _stopWatch.start();
  }

  // ...........................................................................
  Future<void> _sendDataToServer() async {
    log?.call('Sending buffer of size ${_buffer!.lengthInBytes}...');
    await connection.sendData(_buffer!);
  }

  // ...........................................................................
  void _stopTimeMeasurement() {
    log?.call('Stop time measurement ...');
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
  void _exportMeasuredResults() async {
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
      csv += ',';
    }
    csv += '\n';

    for (var i = 0; i < maxNumMeasurements; i++) {
      var numOfIterations = i + 1;

      csv += '$numOfIterations';
      csv += ',';
      log?.call('Num: $numOfIterations');

      for (var packetSize in packageSizes) {
        var size = packetSize;
        var times = _measurementResults[packetSize]![i];

        csv += '$times';
        if (i <= maxNumMeasurements) {
          csv += ',';
        }

        log?.call('$size: $times');
      }
      csv += '\n';
    }

    if (!isTest) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('measurements.csv', csv);
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
}

// #############################################################################
DataRecorder exampleMasterDataRecorder({Connection? connection}) =>
    DataRecorder(
      connection: connection ?? exampleConnection(),
      role: MeasurmentRole.master,
    );

// #############################################################################
DataRecorder exampleSlaveDataRecorder({Connection? connection}) => DataRecorder(
      connection: connection ?? exampleConnection(),
      role: MeasurmentRole.slave,
    );
