// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../../com/nearby/nb_service.dart';
import '../measure.dart';
import '../types.dart';

class MeasureNb extends Measure {
  MeasureNb({
    required super.role,
    super.log,
  }) : super(
          networkService: NbService(
            service: const NbServiceInfo(
              type: 'mobile_network_evaluator_measure_nearby',
            ),
            role: role,
            log: log,
          ),
        );
}

// #############################################################################
MeasureNb exampleMeasureNearby({
  EndpointRole role = EndpointRole.advertizer,
}) =>
    MeasureNb(role: role);
