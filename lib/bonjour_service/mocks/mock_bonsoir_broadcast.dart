// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

class MockBonsoirBroadCast implements BonsoirBroadcast {
  // ...........................................................................
  MockBonsoirBroadCast({
    required this.service,
  });

  // ...........................................................................
  final readyIn = Completer<bool>();
  @override
  Future<void> get ready async => readyIn.future;

  // ...........................................................................
  @override
  final BonsoirService service;

  // ...........................................................................
  @override
  bool isReady = false;

  // ...........................................................................
  @override
  bool isStopped = true;

  // ...........................................................................
  final startIn = Completer<void>();
  @override
  Future<void> start() => startIn.future;

  // ...........................................................................
  final stopIn = Completer<void>();
  @override
  Future<void> stop() => stopIn.future;

  // ...........................................................................
  final eventStreamIn = StreamController<BonsoirBroadcastEvent>();

  // ...........................................................................
  @override
  Stream<BonsoirBroadcastEvent>? get eventStream => eventStreamIn.stream;

  // ...........................................................................
  @override
  Map<String, dynamic> toJson() => {};
}
