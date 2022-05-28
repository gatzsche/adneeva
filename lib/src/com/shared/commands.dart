// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../measure/types.dart';

part 'commands.g.dart';

// #############################################################################
abstract class Command {
  // ...........................................................................
  const Command();

  // ...........................................................................
  String get id;

  // ...........................................................................
  Map<String, dynamic> toJson();

  // ...........................................................................
  String toJsonString() => json.encode(toJson());

  // ...........................................................................
  Map<String, dynamic> _addId(Map<String, dynamic> jsonObject) {
    jsonObject['id'] = id;
    return jsonObject;
  }
}

// #############################################################################
@JsonSerializable()
class EndpointRoleCmd extends Command {
  EndpointRoleCmd({
    required this.mode,
    required this.role,
  }) : super();

  // ...........................................................................
  @override
  @JsonKey()
  final String id = 'EndpointRoleCmd';

  // ...........................................................................
  @JsonKey()
  final MeasurementMode mode;

  // ...........................................................................
  @JsonKey()
  final EndpointRole role;

  // ...........................................................................
  factory EndpointRoleCmd.fromJson(Map<String, dynamic> json) =>
      _$EndpointRoleCmdFromJson(json);

  factory EndpointRoleCmd.fromJsonString(String string) =>
      EndpointRoleCmd.fromJson(
        json.decode(string),
      );

  // ...........................................................................
  @override
  Map<String, dynamic> toJson() => _addId(_$EndpointRoleCmdToJson(this));
}

// .............................................................................
final exampleEndpointRoleCmd = EndpointRoleCmd(
  mode: MeasurementMode.btle,
  role: EndpointRole.advertizer,
);

// #############################################################################
@JsonSerializable()
class StartMeasurementCmd extends Command {
  StartMeasurementCmd() : super();

  // ...........................................................................
  @override
  @JsonKey()
  final String id = 'StartMeasurementCmd';

  // ...........................................................................
  factory StartMeasurementCmd.fromJson(Map<String, dynamic> json) =>
      _$StartMeasurementCmdFromJson(json);

  factory StartMeasurementCmd.fromJsonString(String string) =>
      StartMeasurementCmd.fromJson(
        json.decode(string),
      );

  // ...........................................................................
  @override
  Map<String, dynamic> toJson() => _addId(_$StartMeasurementCmdToJson(this));
}

// .............................................................................
final exampleStartMeasurementCmd = StartMeasurementCmd();

// #############################################################################
@JsonSerializable()
class StopMeasurementCmd extends Command {
  StopMeasurementCmd() : super();

  // ...........................................................................
  @override
  @JsonKey()
  final String id = 'StopMeasurementCmd';

  // ...........................................................................
  factory StopMeasurementCmd.fromJson(Map<String, dynamic> json) =>
      _$StopMeasurementCmdFromJson(json);

  factory StopMeasurementCmd.fromJsonString(String string) =>
      StopMeasurementCmd.fromJson(
        json.decode(string),
      );

  // ...........................................................................
  @override
  Map<String, dynamic> toJson() => _addId(_$StopMeasurementCmdToJson(this));
}

// .............................................................................
final exampleStopMeasurementCmd = StopMeasurementCmd();
