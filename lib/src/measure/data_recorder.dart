// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../com/shared/connection.dart';
import 'types.dart';

class DataRecorder {
  DataRecorder({
    required this.connection,
    required this.role,
  });

  // ...........................................................................
  final Connection connection;
  final MeasurmentRole role;

  // ...........................................................................
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
}

// #############################################################################
DataRecorder exampleMasterDataRecorder() => DataRecorder(
      connection: exampleConnection(),
      role: MeasurmentRole.master,
    );

// #############################################################################
DataRecorder exampleSlaveDataRecorder() => DataRecorder(
      connection: exampleConnection(),
      role: MeasurmentRole.master,
    );
