// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
enum MeasurmentMode {
  idle,
  tcp,
  nearby,
  btle,
}

extension MeasurmentModeToString on MeasurmentMode {
  String get string => toString().split('.').last;
}

// .............................................................................
enum MeasurmentRole {
  master,
  slave,
}

extension MeasurmentRoleToString on MeasurmentRole {
  String get string => toString().split('.').last;
}

// .............................................................................
enum NetworkServiceMode {
  master,
  slave,
  masterAndSlave,
}

typedef Log = Function(String);
