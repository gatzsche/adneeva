// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:bonsoir/bonsoir.dart';

import '../../com/tcp/bonjour_service.dart';
import '../../utils/utils.dart';
import '../measure.dart';
import '../types.dart';

class MeasureTcp extends Measure {
  MeasureTcp({
    required super.role,
    super.log,
  }) : super(
          networkService: BonjourService(
            service: BonsoirService(
              name: 'Measure TCP ${randomPort()}',
              port: randomPort(),
              type: '_mobile_network_evaluator_measure_tcp._tcp',
            ),
            role: role == EndpointRole.advertizer
                ? EndpointRole.advertizer
                : EndpointRole.scanner,
            log: log,
          ),
        );
}

// #############################################################################
MeasureTcp exampleMeasureTcp({
  EndpointRole role = EndpointRole.advertizer,
}) =>
    MeasureTcp(role: role);
