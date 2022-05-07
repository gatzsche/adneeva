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
  @JsonKey()
  String get id;

  // ...........................................................................
  Map<String, dynamic> toJson();

  // ...........................................................................
  String toJsonString() => json.encode(toJson());
}

// #############################################################################
@JsonSerializable()
class MeasurmentModeCmd extends Command {
  MeasurmentModeCmd({
    required this.mode,
    required this.role,
    this.id = 'MeasurmentModeCmd',
  }) : super();

  // ...........................................................................
  @override
  @JsonKey()
  final String id;

  // ...........................................................................
  @JsonKey()
  final MeasurmentMode mode;

  // ...........................................................................
  @JsonKey()
  final MeasurmentRole role;

  // ...........................................................................
  factory MeasurmentModeCmd.fromJson(Map<String, dynamic> json) =>
      _$MeasurmentModeCmdFromJson(json);

  factory MeasurmentModeCmd.fromJsonString(String string) =>
      MeasurmentModeCmd.fromJson(
        json.decode(string),
      );

  // ...........................................................................
  @override
  Map<String, dynamic> toJson() => _$MeasurmentModeCmdToJson(this);
}

// .............................................................................
final exampleMeasurmentModeCmd = MeasurmentModeCmd(
  mode: MeasurmentMode.tcp,
  role: MeasurmentRole.master,
);
