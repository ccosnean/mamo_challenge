import 'package:payments_app/features/payments/domain/domain.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String payments = '/payments';
  static const String accounts = '/accounts';

  static const String paymentDetailsPattern = '/payment/:id';

  static String paymentDetails(PaymentId id) =>
      '/payment/${Uri.encodeComponent(id.value)}';
}
