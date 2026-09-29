import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/features/auth/domain/domain.dart';

enum LoginStatus { idle, submitting, invalidCredentials, failed }

/// Signs in with the given credentials. Success needs no state here: the
/// session changes and the router moves on.
class LoginCubit extends Cubit<LoginStatus> {
  LoginCubit(this._repository) : super(LoginStatus.idle);

  static final Logger _log = Logger('LoginCubit');

  final AuthRepository _repository;

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (state == LoginStatus.submitting) return;
    emit(LoginStatus.submitting);
    _log.info('Sign-in submitted');
    try {
      await _repository.signIn(username: username, password: password);
      if (!isClosed) emit(LoginStatus.idle);
    } on InvalidCredentialsException {
      _log.warning('Sign-in: credentials not recognised');
      if (!isClosed) emit(LoginStatus.invalidCredentials);
    } on Object catch (error, stackTrace) {
      _log.severe('Sign-in failed', error, stackTrace);
      if (!isClosed) emit(LoginStatus.failed);
    }
  }
}
