// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

enum MeasurmentMode {
  idle,
  tcp,
  nearby,
  btle,
}

enum MeasurmentRole {
  master,
  slave,
}

enum NetworkServiceMode {
  master,
  slave,
  masterAndSlave,
}

typedef Log = Function(String);
