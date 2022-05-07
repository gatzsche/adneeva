// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/com/shared/commands.dart';

void main() {
  group('$MeasurmentModeCmd', () {
    test('should be able to serialize to JSON and parse from JSON', () {
      final input = exampleMeasurmentModeCmd;
      final intputJsonMap = input.toJson();
      final inputJsonString = input.toJsonString();
      final outputJsonMap = json.decode(inputJsonString);
      final output = MeasurmentModeCmd.fromJsonString(inputJsonString);

      expect(intputJsonMap['id'], '$MeasurmentModeCmd');
      expect(outputJsonMap['id'], '$MeasurmentModeCmd');
      expect(input.id, output.id);
      expect(input.mode, output.mode);
      expect(input.role, output.role);
    });
  });
}
