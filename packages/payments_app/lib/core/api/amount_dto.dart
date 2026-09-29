import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';

part 'amount_dto.freezed.dart';
part 'amount_dto.g.dart';

/// `{"amount": "1200.00", "currency": "AED"}`: amounts travel as decimal
/// strings, so no floating point number ever touches money.
@freezed
abstract class AmountDto with _$AmountDto {
  const factory AmountDto({required String amount, required String currency}) =
      _AmountDto;

  factory AmountDto.fromJson(Map<String, dynamic> json) =>
      _$AmountDtoFromJson(json);
}

extension AmountDtoMapper on AmountDto {
  /// Exact; throws a [FormatException] for a malformed amount or an
  /// unsupported currency.
  Money toDomain() => Money.parse(amount, Currency.fromCode(currency));
}
