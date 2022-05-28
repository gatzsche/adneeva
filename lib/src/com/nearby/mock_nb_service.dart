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
const serviceInfo = NbServiceInfo();

// .............................................................................
class MockNbService extends NbService {
  MockNbService({
    required super.role,
    required super.log,
  }) : super(
          service: serviceInfo,
        ) {
    log = (str) => loggedData.add(str);
  }

  final List<String> loggedData = [];
}
