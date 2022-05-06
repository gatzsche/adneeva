// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_network_evaluator/src/utils/utils.dart';

void main() {
  test('String.uint8List, Uint8List.string', () {
    const input = 'hello';
    final uint8 = input.uint8List;
    final output = uint8.string;
    expect(input, output);
  });

  test('randomPort', () {
    expect(randomPort(), greaterThanOrEqualTo(12345));
    expect(randomPort(), lessThanOrEqualTo(12345 + 30000));
  });
}
