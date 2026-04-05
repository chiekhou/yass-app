import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// ==================== EVENTS ====================

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthLoginWithPhoneRequested extends AuthEvent {
  final String phone;
  final String password;

  const AuthLoginWithPhoneRequested({
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phone;
  final String? wilayaId;
  final String? gender;
  final int? age;

  const AuthRegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phone,
    this.wilayaId,
    this.gender,
    this.age,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, password, phone, wilayaId, gender, age];
}

class AuthRegisterWithPhoneRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final String password;
  final String? wilayaId;
  final String? gender;
  final int? age;

  const AuthRegisterWithPhoneRequested({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.password,
    this.wilayaId,
    this.gender,
    this.age,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, password, wilayaId, gender, age];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUpdateProfile extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? wilayaId;
  final String? avatar;

  const AuthUpdateProfile({
    this.firstName,
    this.lastName,
    this.phone,
    this.wilayaId,
    this.avatar,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, wilayaId, avatar];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthForgotPasswordByPhoneRequested extends AuthEvent {
  final String phone;
  const AuthForgotPasswordByPhoneRequested({required this.phone});
  @override
  List<Object?> get props => [phone];
}

class AuthResetPasswordByPhoneRequested extends AuthEvent {
  final String phone;
  final String otp;
  final String newPassword;
  const AuthResetPasswordByPhoneRequested({
    required this.phone,
    required this.otp,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [phone, otp, newPassword];
}

class AuthRegisterPartnerRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final String companyName;
  final String? registrationNumber;
  final String? taxId;
  final String? wilayaId;

  const AuthRegisterPartnerRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.companyName,
    this.registrationNumber,
    this.taxId,
    this.wilayaId,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        password,
        phone,
        companyName,
        registrationNumber,
        taxId,
        wilayaId,
      ];
}

class AuthUpdatePartnerProfile extends AuthEvent {
  final String? companyName;
  final String? registrationNumber;
  final String? taxId;

  const AuthUpdatePartnerProfile({
    this.companyName,
    this.registrationNumber,
    this.taxId,
  });

  @override
  List<Object?> get props => [companyName, registrationNumber, taxId];
}

class AuthSendEmailOtpRequested extends AuthEvent {
  const AuthSendEmailOtpRequested();
}

class AuthSendPhoneOtpRequested extends AuthEvent {
  const AuthSendPhoneOtpRequested();
}

class AuthVerifyEmailOtpRequested extends AuthEvent {
  final String otp;

  const AuthVerifyEmailOtpRequested({required this.otp});

  @override
  List<Object?> get props => [otp];
}

class AuthVerifyPhoneOtpRequested extends AuthEvent {
  final String otp;

  const AuthVerifyPhoneOtpRequested({required this.otp});

  @override
  List<Object?> get props => [otp];
}

// ==================== STATES ====================

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthPendingVerification extends AuthState {
  final User user;
  final String verificationType; // 'email' | 'phone'

  const AuthPendingVerification({
    required this.user,
    required this.verificationType,
  });

  @override
  List<Object?> get props => [user, verificationType];
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent();
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthForgotPasswordSuccess extends AuthState {
  final String message;

  const AuthForgotPasswordSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthForgotPasswordPhoneSent extends AuthState {
  final String phone;
  const AuthForgotPasswordPhoneSent({required this.phone});
  @override
  List<Object?> get props => [phone];
}

class AuthResetPasswordByPhoneSuccess extends AuthState {
  const AuthResetPasswordByPhoneSuccess();
}

class AuthVerificationSuccess extends AuthState {
  final User user;

  const AuthVerificationSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

// ==================== BLOC ====================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository = AuthRepository();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLoginWithPhoneRequested>(_onAuthLoginWithPhoneRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthRegisterWithPhoneRequested>(_onAuthRegisterWithPhoneRequested);
    on<AuthRegisterPartnerRequested>(_onAuthRegisterPartnerRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUpdateProfile>(_onAuthUpdateProfile);
    on<AuthUpdatePartnerProfile>(_onAuthUpdatePartnerProfile);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthForgotPasswordByPhoneRequested>(_onAuthForgotPasswordByPhoneRequested);
    on<AuthResetPasswordByPhoneRequested>(_onAuthResetPasswordByPhoneRequested);
    on<AuthSendEmailOtpRequested>(_onAuthSendEmailOtpRequested);
    on<AuthSendPhoneOtpRequested>(_onAuthSendPhoneOtpRequested);
    on<AuthVerifyEmailOtpRequested>(_onAuthVerifyEmailOtpRequested);
    on<AuthVerifyPhoneOtpRequested>(_onAuthVerifyPhoneOtpRequested);
  }

  String _verificationType(User user) =>
      user.email.isEmpty ? 'phone' : 'email';

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        if (user.status == 'pending') {
          emit(AuthPendingVerification(
            user: user,
            verificationType: _verificationType(user),
          ));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      if (user.status == 'pending') {
        emit(AuthPendingVerification(user: user, verificationType: 'email'));
      } else {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      // Do NOT emit AuthUnauthenticated here — it would trigger a redirect
      // to the home page via the global BlocListener in main.dart
    }
  }

  Future<void> _onAuthLoginWithPhoneRequested(
    AuthLoginWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginWithPhone(
        phone: event.phone,
        password: event.password,
      );
      if (user.status == 'pending') {
        emit(AuthPendingVerification(user: user, verificationType: 'phone'));
      } else {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      // Do NOT emit AuthUnauthenticated here — it would trigger a redirect
      // to the home page via the global BlocListener in main.dart
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
        phone: event.phone,
        wilayaId: event.wilayaId,
        gender: event.gender,
        age: event.age,
      );
      if (user.status == 'pending') {
        emit(AuthPendingVerification(user: user, verificationType: 'email'));
      } else {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRegisterWithPhoneRequested(
    AuthRegisterWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.registerWithPhone(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        password: event.password,
        wilayaId: event.wilayaId,
        gender: event.gender,
        age: event.age,
      );
      if (user.status == 'pending') {
        emit(AuthPendingVerification(user: user, verificationType: 'phone'));
      } else {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRegisterPartnerRequested(
    AuthRegisterPartnerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.registerPartner(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
        phone: event.phone,
        companyName: event.companyName,
        registrationNumber: event.registrationNumber,
        taxId: event.taxId,
        wilayaId: event.wilayaId,
      );
      if (user.status == 'pending') {
        emit(AuthPendingVerification(user: user, verificationType: 'email'));
      } else {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthUpdateProfile(
    AuthUpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthLoading());
      try {
        final user = await _authRepository.updateProfile(
          firstName: event.firstName,
          lastName: event.lastName,
          phone: event.phone,
          wilayaId: event.wilayaId,
          avatar: event.avatar,
        );
        emit(AuthAuthenticated(user: user));
      } catch (e) {
        emit(AuthError(message: e.toString()));
        emit(AuthAuthenticated(user: currentState.user));
      }
    }
  }

  Future<void> _onAuthUpdatePartnerProfile(
    AuthUpdatePartnerProfile event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthLoading());
      try {
        final partnerProfile = await _authRepository.updatePartnerProfile(
          companyName: event.companyName,
          registrationNumber: event.registrationNumber,
          taxId: event.taxId,
        );
        final updatedUser = currentState.user.copyWith(
          partnerProfile: partnerProfile,
        );
        emit(AuthAuthenticated(user: updatedUser));
      } catch (e) {
        emit(AuthError(message: e.toString()));
        emit(AuthAuthenticated(user: currentState.user));
      }
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.forgotPassword(email: event.email);
      emit(const AuthForgotPasswordSuccess(
        message: 'Un email de réinitialisation a été envoyé',
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthForgotPasswordByPhoneRequested(
    AuthForgotPasswordByPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.forgotPasswordByPhone(phone: event.phone);
      emit(AuthForgotPasswordPhoneSent(phone: event.phone));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthResetPasswordByPhoneRequested(
    AuthResetPasswordByPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPasswordByPhone(
        phone: event.phone,
        otp: event.otp,
        newPassword: event.newPassword,
      );
      emit(const AuthResetPasswordByPhoneSuccess());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSendEmailOtpRequested(
    AuthSendEmailOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendEmailOtp();
      emit(const AuthOtpSent());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSendPhoneOtpRequested(
    AuthSendPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPhoneOtp();
      emit(const AuthOtpSent());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthVerifyEmailOtpRequested(
    AuthVerifyEmailOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.verifyEmailOtp(otp: event.otp);
      if (user.isAdmin || user.isPartner) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthVerificationSuccess(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthVerifyPhoneOtpRequested(
    AuthVerifyPhoneOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.verifyPhoneOtp(otp: event.otp);
      if (user.isAdmin || user.isPartner) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthVerificationSuccess(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
