// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:math';
import 'dart:typed_data';

int randomPort() => 12345 + Random().nextInt(30000);

// .............................................................................
extension StringConversion on Uint8List {
  String get string {
    return String.fromCharCodes(this);
  }
  // ···
}

// .............................................................................
extension Uint8Conversion on String {
  Uint8List get uint8List {
    return Uint8List.fromList(codeUnits);
  }
}
