// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import '../application.dart';
import '../measure/types.dart';

class MeasurementWidget extends StatefulWidget {
  const MeasurementWidget({
    Key? key,
    required this.application,
    this.log,
  }) : super(key: key);

  final Application application;
  final Stream<String>? log;

  @override
  State<MeasurementWidget> createState() => _MeasurementWidgetState();
}

class _MeasurementWidgetState extends State<MeasurementWidget> {
  // ...........................................................................
  @override
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
    super.dispose();
  }

  // ...........................................................................
  @override
  void initState() {
    _initLog();

    super.initState();
  }

  // ...........................................................................
  String _lastLogMessage = '';
  void _initLog() {
    final s = widget.log?.listen(
      (event) => _lastLogMessage = event,
    );
    _dispose.add(
      () => s?.cancel(),
    );
  }

  // ...........................................................................
  @override
  Widget build(BuildContext context) {
    final needsRebuild = StreamGroup.merge<dynamic>([
      widget.application.isConnected,
      widget.application.role.stream,
      widget.application.isMeasuring,
      widget.application.measurementResults,
    ]);

    return StreamBuilder(
      stream: needsRebuild,
      builder: (context, _) {
        return _showSlaveMeasuringWidget
            ? _slaveIsMeasuringWidget
            : _isConnected
                ? _contentWidget
                : _waitingForRemoteWidget;
      },
    );
  }

  // ...........................................................................
  final List<Function()> _dispose = [];

  // ...........................................................................
  bool get _showSlaveMeasuringWidget {
    return widget.application.role.value == EndpointRole.slave &&
        widget.application.isMeasuring.value;
  }

  // ...........................................................................
  bool get _isConnected => widget.application.isConnected.value;

  // ...........................................................................
  Widget get _contentWidget {
    return Center(
      child: Column(
        children: [
          const Expanded(
            child: SizedBox(),
          ),
          _controlButton,
          const SizedBox(
            height: 30,
          ),
          _logWidget,
          _measurementResults,
          const Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }

  // ...........................................................................
  Widget get _waitingForRemoteWidget {
    return const Center(
      key: Key('waitingForRemoteWidget'),
      child: Text('Waiting for second device'),
    );
  }

  // ...........................................................................
  Widget get _slaveIsMeasuringWidget {
    return Center(
      key: const Key('slaveIsMeasuringWidget'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(
            height: 30,
          ),
          Text('Recording measurements'),
        ],
      ),
    );
  }

  // ...........................................................................
  Widget get _logWidget {
    if (widget.log == null) {
      return const SizedBox();
    }

    return StreamBuilder<String>(
      stream: widget.log,
      builder: (context, snapshot) {
        return Text(_lastLogMessage);
      },
    );
  }

  // ...........................................................................
  Widget get _controlButton {
    return StreamBuilder(
      stream: widget.application.isMeasuring,
      builder: (context, snapshot) {
        return widget.application.isMeasuring.value
            ? _stopButton
            : _startButton;
      },
    );
  }

  // ...........................................................................
  Widget get _startButton {
    return ElevatedButton(
      key: const Key('startButton'),
      onPressed: widget.application.startMeasurements,
      child: const Text('Start'),
    );
  }

  // ...........................................................................
  Widget get _stopButton {
    return ElevatedButton(
      key: const Key('stopButton'),
      onPressed: widget.application.stopMeasurements,
      child: const Text('Stop'),
    );
  }

  // ...........................................................................
  Widget get _measurementResults {
    return StreamBuilder(
      stream: widget.application.measurementResults,
      builder: (context, snapshot) {
        return widget.application.measurementResults.value.isNotEmpty
            ?
            // ignore: prefer_const_constructors
            Text(
                key:
                    // ignore: prefer_const_constructors
                    Key('measurementResults'),
                'Download measurement results',
              )
            : const SizedBox();
      },
    );
  }
}
