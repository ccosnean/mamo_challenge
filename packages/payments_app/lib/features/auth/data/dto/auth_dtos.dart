import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:payments_app/features/auth/domain/domain.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

/// Token endpoint response (RFC 6749 §5.1).
@freezed
abstract class TokenResponseDto with _$TokenResponseDto {
  const factory TokenResponseDto({
    required String accessToken,
    required String tokenType,
    required int expiresIn,
  }) = _TokenResponseDto;

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseDtoFromJson(json);

  const TokenResponseDto._();

  /// Tokens are credentials: never printed.
  @override
  String toString() => 'TokenResponseDto(<redacted>, expiresIn: $expiresIn)';
}

@freezed
abstract class CompanyDto with _$CompanyDto {
  const factory CompanyDto({required String id, required String name}) =
      _CompanyDto;

  factory CompanyDto.fromJson(Map<String, dynamic> json) =>
      _$CompanyDtoFromJson(json);
}

/// `GET /me`.
@freezed
abstract class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String username,
    required String name,
    required CompanyDto company,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  const UserDto._();

  /// Names are personal data.
  @override
  String toString() => 'UserDto(id: $id)';
}

extension UserDtoMapper on UserDto {
  User toDomain() => User(
    id: id,
    username: username,
    name: name,
    company: Company(id: company.id, name: company.name),
  );
}
