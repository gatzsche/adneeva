// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commands.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EndpointRoleCmd _$EndpointRoleCmdFromJson(Map<String, dynamic> json) =>
    EndpointRoleCmd(
      mode: $enumDecode(_$MeasurementModeEnumMap, json['mode']),
      role: $enumDecode(_$EndpointRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$EndpointRoleCmdToJson(EndpointRoleCmd instance) =>
    <String, dynamic>{
      'mode': _$MeasurementModeEnumMap[instance.mode],
      'role': _$EndpointRoleEnumMap[instance.role],
    };

const _$MeasurementModeEnumMap = {
  MeasurementMode.tcp: 'tcp',
  MeasurementMode.nearby: 'nearby',
  MeasurementMode.btle: 'btle',
};

const _$EndpointRoleEnumMap = {
  EndpointRole.master: 'master',
  EndpointRole.slave: 'slave',
};

StartMeasurementCmd _$StartMeasurementCmdFromJson(Map<String, dynamic> json) =>
    StartMeasurementCmd();

Map<String, dynamic> _$StartMeasurementCmdToJson(
        StartMeasurementCmd instance) =>
    <String, dynamic>{};

StopMeasurementCmd _$StopMeasurementCmdFromJson(Map<String, dynamic> json) =>
    StopMeasurementCmd();

Map<String, dynamic> _$StopMeasurementCmdToJson(StopMeasurementCmd instance) =>
    <String, dynamic>{};
