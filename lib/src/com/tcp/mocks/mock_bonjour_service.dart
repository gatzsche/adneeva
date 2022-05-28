// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################

import 'package:bonsoir/bonsoir.dart';

import '../bonjour_service.dart';
import 'mock_bonsoir_broadcast.dart';
import 'mock_bonsoir_discovery.dart';
import 'mock_network_interface.dart';
import 'mock_server_socket.dart';
import 'mock_socket.dart';

// .............................................................................
class MockBonjourServiceDeps implements BonjourServiceDeps {
  const MockBonjourServiceDeps();

  @override
  final newBonsoirBroadcast = MockBonsoirBroadcast.new;

  @override
  final newBonsoirDiscovery = MockBonsoirDiscovery.new;

  @override
  final bindServerSocket = MockServerSocket.bind;

  @override
  final connectSocket = MockSocket.connect;

  @override
  final listNetworkInterface = MockNetworkInterface.list;
}

// .............................................................................
const description = BonsoirService(
  name: 'Example Bonjour Service',
  port: 12457,
  type: 'example.bonjour.service',
);

// .............................................................................
class MockBonjourService extends BonjourService {
  MockBonjourService({
    required super.role,
  }) : super(
          service: description,
        ) {
    log = (str) => loggedData.add(str);
  }

  final List<String> loggedData = [];
}
