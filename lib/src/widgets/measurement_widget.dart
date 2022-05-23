// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import '../application.dart';
import '../measure/types.dart';

class MeasurementWidget extends StatelessWidget {
  const MeasurementWidget({
    Key? key,
    required this.application,
    this.log,
  }) : super(key: key);

  final Application application;
  final Stream<String>? log;

  // ...........................................................................
  @override
  Widget build(BuildContext context) {
    final needsRebuild = StreamGroup.merge<dynamic>([
      application.isConnected,
      application.role.stream,
      application.isMeasuring,
      application.measurementResults,
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
  bool get _showSlaveMeasuringWidget {
    return application.role.value == EndpointRole.slave &&
        application.isMeasuring.value;
  }

  // ...........................................................................
  bool get _isConnected => application.isConnected.value;

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
      child: Text('Waiting for second device ...'),
    );
  }

  // ...........................................................................
  Widget get _slaveIsMeasuringWidget {
    return Center(
      key: const Key('slaveIsMeasuringWidget'),
      child: Column(children: const [
        CircularProgressIndicator(),
        Text('Recording measurements ...')
      ]),
    );
  }

  // ...........................................................................
  Widget get _logWidget {
    if (log == null) {
      return const SizedBox();
    }

    return StreamBuilder<String>(
      stream: log,
      builder: (context, snapshot) {
        return Text(snapshot.data ?? '');
      },
    );
  }

  // ...........................................................................
  Widget get _controlButton {
    return StreamBuilder(
      stream: application.isMeasuring,
      builder: (context, snapshot) {
        return application.isMeasuring.value ? _stopButton : _startButton;
      },
    );
  }

  // ...........................................................................
  Widget get _startButton {
    return ElevatedButton(
      key: const Key('startButton'),
      onPressed: application.startMeasurements,
      child: const Text('Start'),
    );
  }

  // ...........................................................................
  Widget get _stopButton {
    return ElevatedButton(
      key: const Key('stopButton'),
      onPressed: application.startMeasurements,
      child: const Text('Stop'),
    );
  }

  // ...........................................................................
  Widget get _measurementResults {
    return StreamBuilder(
      stream: application.measurementResults,
      builder: (context, snapshot) {
        return application.measurementResults.value.isNotEmpty
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
