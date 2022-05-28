// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################

import 'mock_nearby_service.dart';
import 'nb_service.dart';

// .............................................................................
class MockNbServiceDeps implements NbServiceDeps {
  const MockNbServiceDeps();

  @override
  final newNearbyService = MockNearbyService.new;
}

// .............................................................................
final mockServiceInfo = NbServiceInfo(
  type: 'mne-measurenb',
  deviceId: 'mock-device',
);

// .............................................................................
class MockNbService extends NbService {
  MockNbService({
    required super.role,
    required super.log,
  }) : super(
          service: mockServiceInfo,
        ) {
    log = (str) => loggedData.add(str);
  }

  final List<String> loggedData = [];
}
