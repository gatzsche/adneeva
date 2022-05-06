// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:gg_value/gg_value.dart';

import 'types.dart';

class Measure {
  Measure({
    required this.role,
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
  final MeasurmentRole role;

  // ...........................................................................
  @mustCallSuper
  Future<void> start() async {}

  @mustCallSuper
  Future<void> stop() async {}

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

Measure exampleMeasure({
  MeasurmentRole role = MeasurmentRole.master,
}) {
  return Measure(role: role);
}
