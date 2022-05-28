// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
enum MeasurementMode {
  tcp,
  nearby,
  btle,
}

extension MeasurementModeToString on MeasurementMode {
  String get string => toString().split('.').last;
}

// .............................................................................
enum EndpointRole {
  advertizer,
  scanner,
}

extension EndpointRoleToString on EndpointRole {
  String get string => toString().split('.').last;
}

typedef Log = Function(String);
