import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_event.dart';
import 'login_state.dart';
import '../repository/auth_repository.dart';
import 'package:flutter/foundation.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc(this.authRepository) : super(const LoginState()) {
    on<GoogleLoginRequested>(_onGoogleLogin);
    on<FacebookLoginRequested>(_onFacebookLogin);
  }

  Future<void> _onGoogleLogin(
    GoogleLoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginState(status: LoginStatus.loading));

    try {
      final user = await authRepository.signInWithGoogle();

      if (user != null) {
        emit(const LoginState(status: LoginStatus.success));
      } else {
        emit(
          const LoginState(
            status: LoginStatus.failure,

            errorMessage: 'Google login cancelled',
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Google Login Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        LoginState(
          status: LoginStatus.failure,
          errorMessage: 'Google login failed: $e',
        ),
      );
    }
  }

  Future<void> _onFacebookLogin(
    FacebookLoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginState(status: LoginStatus.loading));

    try {
      final user = await authRepository.signInWithFacebook();

      if (user != null) {
        emit(const LoginState(status: LoginStatus.success));
      } else {
        emit(
          const LoginState(
            status: LoginStatus.failure,
            errorMessage: 'Facebook login cancelled',
          ),
        );
      }
    } catch (e) {
      emit(
        const LoginState(
          status: LoginStatus.failure,
          errorMessage: 'Facebook login failed',
        ),
      );
    }
  }
}
