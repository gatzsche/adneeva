// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:adneeva/src/com/shared/commands.dart';

void main() {
  group('$EndpointRoleCmd', () {
    test('should be able to serialize to JSON and parse from JSON', () {
      final input = exampleEndpointRoleCmd;
      final intputJsonMap = input.toJson();
      final inputJsonString = input.toJsonString();
      final outputJsonMap = json.decode(inputJsonString);
      final output = EndpointRoleCmd.fromJsonString(inputJsonString);

      expect(intputJsonMap['id'], '$EndpointRoleCmd');
      expect(outputJsonMap['id'], '$EndpointRoleCmd');
      expect(input.id, output.id);
      expect(input.mode, output.mode);
      expect(input.role, output.role);
    });

    group('$StartMeasurementCmd', () {
      test('should be able to serialize to JSON and parse from JSON', () {
        final cmd = exampleStartMeasurementCmd;
        final jsonMap = cmd.toJson();
        final jsonString = json.encode(jsonMap);
        expect(jsonMap['id'], '$StartMeasurementCmd');
        final cmdOut0 = StartMeasurementCmd.fromJson(jsonMap);
        final cmdOut1 = StartMeasurementCmd.fromJsonString(jsonString);
        expect(cmdOut0, isNotNull);
        expect(cmdOut1, isNotNull);
      });
    });

    group('$StopMeasurementCmd', () {
      test('should be able to serialize to JSON and parse from JSON', () {
        final cmd = exampleStopMeasurementCmd;
        final jsonMap = cmd.toJson();
        final jsonString = json.encode(jsonMap);
        expect(jsonMap['id'], '$StopMeasurementCmd');
        final cmdOut0 = StopMeasurementCmd.fromJson(jsonMap);
        final cmdOut1 = StopMeasurementCmd.fromJsonString(jsonString);
        expect(cmdOut0, isNotNull);
        expect(cmdOut1, isNotNull);
      });
    });
  });
}
