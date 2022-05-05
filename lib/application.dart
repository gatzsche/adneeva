// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';
import 'dart:math';

import 'bonjour_service/bonjour_service.dart';
import 'network_service.dart';

class Application {
  Application() {
    _initRemoteControl();
  }

  // ...........................................................................
  void dispose() {
    for (final d in _dispose) {
      d();
    }
  }

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];

  // ...........................................................................
  Future<String> get _ipAddress async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        return addr.address;
      }
    }

    return '127.0.0.1';
  }

  // ...........................................................................
  late BonjourService _remoteControl;
  void _initRemoteControl() async {
    final ip = await _ipAddress;

    _remoteControl = BonjourService(
      mode: NetworkServiceMode.masterAndSlave,
      description: BonjourServiceDescription(
          ipAddress: ip,
          name: 'Mobile Network Evaluator',
          port: 1234 + Random().nextInt(10000),
          serviceId: '_mobile_network_evaluator._tcp'),
    );

    _remoteControl.start();
  }
}

// #############################################################################
Application exampleApplication() => Application();
