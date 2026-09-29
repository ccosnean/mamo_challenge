import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:payments_app/core/api/amount_dto.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/features/account/domain/domain.dart';

part 'account_dto.freezed.dart';
part 'account_dto.g.dart';

/// An item of `GET /accounts`.
@freezed
abstract class AccountDto with _$AccountDto {
  const factory AccountDto({
    required String id,
    required String companyId,
    required String name,
    required String iban,
    required AmountDto availableBalance,
  }) = _AccountDto;

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);

  const AccountDto._();

  /// Account numbers are sensitive.
  @override
  String toString() => 'AccountDto(id: $id)';
}

extension AccountDtoMapper on AccountDto {
  /// Validates on the way in: IBAN checksum, amount and currency.
  Account toDomain() => Account(
    id: id,
    companyId: companyId,
    name: name,
    iban: Iban.parse(iban),
    availableBalance: availableBalance.toDomain(),
  );
}
