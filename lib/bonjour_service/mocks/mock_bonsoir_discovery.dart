// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

class MockBonsoirDiscovery extends Mock implements BonsoirDiscovery {
  MockBonsoirDiscovery({
    bool printLogs = kDebugMode,
    required this.type,
  });

  @override
  final String type;

  @override
  bool isReady = false;

  @override
  bool isStopped = true;

  @override
  Future<bool> get ready async {
    return true;
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  // ...........................................................................
  final eventStreamIn = StreamController<BonsoirDiscoveryEvent>();
  @override
  Stream<BonsoirDiscoveryEvent>? get eventStream => eventStreamIn.stream;
}
