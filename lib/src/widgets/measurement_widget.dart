// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import '../application.dart';

class MeasurementWidget extends StatelessWidget {
  const MeasurementWidget({
    Key? key,
    required this.application,
  }) : super(key: key);

  final Application application;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: application.isConnected,
      builder: (context, snapshot) {
        return application.isConnected.value
            ? _contentWidget
            : _waitingForRemoteWidget;
      },
    );
  }

  // ...........................................................................
  Widget get _contentWidget {
    return Column(
      children: [
        _controlButton,
        _measurmentResults,
      ],
    );
  }

  // ...........................................................................
  Widget get _waitingForRemoteWidget {
    return Center(
      key: const Key('waitingForRemoteWidget'),
      child: Column(children: const [
        CircularProgressIndicator(),
        Text('Waiting for second device to connect ...')
      ]),
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
  Widget get _measurmentResults {
    return StreamBuilder(
      stream: application.measurementResults,
      builder: (context, snapshot) {
        return application.measurementResults.value.isNotEmpty
            ? Text(
                key: Key('measurmentResults'),
                'Download measurement results',
              )
            : const SizedBox();
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
}
