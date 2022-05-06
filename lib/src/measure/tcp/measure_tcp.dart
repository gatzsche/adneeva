// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../measure.dart';

class MeasureTcp extends Measure {
  MeasureTcp() {
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

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
}

// #############################################################################
MeasureTcp exampleMeasureTcp() => MeasureTcp();
