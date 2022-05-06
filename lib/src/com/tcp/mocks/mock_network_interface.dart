// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:mocktail/mocktail.dart';

class MockNetworkInterface extends Mock implements NetworkInterface {
  // ...........................................................................
  static Future<List<NetworkInterface>> list({
    bool includeLoopback = false,
    bool includeLinkLocal = false,
    InternetAddressType type = InternetAddressType.any,
  }) async {
    return [
      MockNetworkInterface(),
    ];
  }

  // ...........................................................................
  @override
  List<InternetAddress> get addresses => [
        InternetAddress('192.168.178.1'),
      ];
}
