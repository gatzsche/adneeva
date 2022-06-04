// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../../com/nearby/nb_service.dart';
import '../../utils/utils.dart';
import '../measure.dart';
import '../types.dart';

class MeasureNb extends Measure {
  MeasureNb({
    required super.role,
    super.log,
  }) : super(
          networkService: NbService(
            service: NbServiceInfo(
              type: 'adneeva-nb',
              deviceId: role == EndpointRole.advertizer
                  ? 'Advertizer ${randomPort()}'
                  : 'Scanner ${randomPort()}',
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
