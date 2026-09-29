import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/features/auth/domain/domain.dart';

/// The signed-in user, or null while signed out. Drives the router's
/// sign-in guard.
class SessionCubit extends Cubit<User?> {
  SessionCubit(this._repository) : super(null) {
    _subscription = _repository.watchCurrentUser().listen((user) {
      if (isClosed) return;
      _log.info(
        user == null
            ? 'Session: signed out'
            : 'Session: ${user.id} (company ${user.company.id})',
      );
      emit(user);
    });
  }

  static final Logger _log = Logger('Session');

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  Future<void> signOut() {
    _log.info('Sign-out requested');
    return _repository.signOut();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
