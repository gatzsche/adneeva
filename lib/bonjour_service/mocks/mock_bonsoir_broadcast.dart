// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

class MockBonsoirBroadcast extends Mock implements BonsoirBroadcast {
  MockBonsoirBroadcast({
    bool printLogs = kDebugMode,
    required this.service,
  });

  /// The service to broadcast.
  @override
  final BonsoirService service;

  @override
  bool isStopped = true;

  @override
  bool isReady = false;

  @override
  Future<bool> get ready async {
    return true;
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
