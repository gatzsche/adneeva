// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../measure.dart';
import '../types.dart';

class MeasureTcp extends Measure {
  MeasureTcp({required MeasurmentRole role}) : super(role: role) {
    _dispose.add(() {});
  }

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
  Future<void> start() async {
    // If master, then create a master bonjour service on the given port
    // Wait for first connection
    // If connection has arrived start the measurement

    // If slave, then create a slave bonjour service on the given port
    // Wait for first connection
    // If connection is done wait for measurments
    // On measurement received, acknowledge
    print('x');

    super.start();
  }

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
}

// #############################################################################
MeasureTcp exampleMeasureTcp({
  MeasurmentRole role = MeasurmentRole.master,
}) =>
    MeasureTcp(role: role);
