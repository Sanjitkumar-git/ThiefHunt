import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

// Google login button click
class GoogleLoginRequested extends LoginEvent {
  const GoogleLoginRequested();
}

// Facebook login button click
class FacebookLoginRequested extends LoginEvent {
  const FacebookLoginRequested();
}
