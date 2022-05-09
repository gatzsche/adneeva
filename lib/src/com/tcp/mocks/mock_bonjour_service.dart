// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################

import 'package:bonsoir/bonsoir.dart';

import '../../../measure/types.dart';
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
  final bonsoirBroadcast = MockBonsoirBroadcast.new;

  @override
  final bonsoirDiscovery = MockBonsoirDiscovery.new;

  @override
  final serverSocketBind = MockServerSocket.bind;

  @override
  final clientSocketConnect = MockSocket.connect;

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
    required EndpointRole mode,
  }) : super(
          service: description,
          mode: mode,
        ) {
    log = (str) => loggedData.add(str);
  }

  final List<String> loggedData = [];
}
