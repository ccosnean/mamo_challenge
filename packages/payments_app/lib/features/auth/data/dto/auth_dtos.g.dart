// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenResponseDto _$TokenResponseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_TokenResponseDto',
      json,
      ($checkedConvert) {
        final val = _TokenResponseDto(
          accessToken: $checkedConvert('access_token', (v) => v as String),
          tokenType: $checkedConvert('token_type', (v) => v as String),
          expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'accessToken': 'access_token',
        'tokenType': 'token_type',
        'expiresIn': 'expires_in',
      },
    );

Map<String, dynamic> _$TokenResponseDtoToJson(_TokenResponseDto instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
    };

_CompanyDto _$CompanyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CompanyDto', json, ($checkedConvert) {
      final val = _CompanyDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CompanyDtoToJson(_CompanyDto instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UserDto', json, ($checkedConvert) {
      final val = _UserDto(
        id: $checkedConvert('id', (v) => v as String),
        username: $checkedConvert('username', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        company: $checkedConvert(
          'company',
          (v) => CompanyDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'name': instance.name,
  'company': instance.company,
};
