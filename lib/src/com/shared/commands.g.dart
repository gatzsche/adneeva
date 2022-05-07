// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commands.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeasurmentModeCmd _$MeasurmentModeCmdFromJson(Map<String, dynamic> json) =>
    MeasurmentModeCmd(
      mode: $enumDecode(_$MeasurmentModeEnumMap, json['mode']),
      role: $enumDecode(_$MeasurmentRoleEnumMap, json['role']),
      id: json['id'] as String? ?? 'MeasurmentModeCmd',
    );

Map<String, dynamic> _$MeasurmentModeCmdToJson(MeasurmentModeCmd instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mode': _$MeasurmentModeEnumMap[instance.mode],
      'role': _$MeasurmentRoleEnumMap[instance.role],
    };

const _$MeasurmentModeEnumMap = {
  MeasurmentMode.idle: 'idle',
  MeasurmentMode.tcp: 'tcp',
  MeasurmentMode.nearby: 'nearby',
  MeasurmentMode.btle: 'btle',
};

const _$MeasurmentRoleEnumMap = {
  MeasurmentRole.master: 'master',
  MeasurmentRole.slave: 'slave',
};
