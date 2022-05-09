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
  MeasureTcp({required EndpointRole role})
      : super(
          role: role,
          networkService: BonjourService(
              service: BonsoirService(
                name: 'Measure TCP',
                port: randomPort(),
                type: '_measure_tcp._tcp',
              ),
              mode: role == EndpointRole.master
                  ? EndpointRole.master
                  : EndpointRole.slave),
        );
}

// #############################################################################
MeasureTcp exampleMeasureTcp({
  EndpointRole role = EndpointRole.master,
}) =>
    MeasureTcp(role: role);
