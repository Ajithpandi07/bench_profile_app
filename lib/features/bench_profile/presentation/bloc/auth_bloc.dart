import 'package:bloc/bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onSignInRequested(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // ignore: avoid_print
    print('AuthBloc: SignInRequested(email: ${event.email})');
    try {
      final failureOrUser = await repository.signInWithEmail(email: event.email, password: event.password);
      failureOrUser.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (user) {
          print('AuthBloc: signIn success uid=${user.uid}');
          emit(Authenticated(user));
        },
      );
    } catch (e, st) {
      print('AuthBloc: unhandled signIn exception -> $e\n$st');
      emit(AuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await repository.signUpWithEmail(email: event.email, password: event.password);
      res.fold((f) => emit(AuthFailure(f.message)), (user) => emit(AuthSignUpSuccess(user.uid)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await repository.sendPasswordReset(event.email);
      res.fold((f) => emit(AuthFailure(f.message)), (_) => emit(AuthPasswordResetSent()));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // ignore: avoid_print
    print('AuthBloc: SignOutRequested');
    try {
      await repository.signOut();
      // ignore: avoid_print
      print('AuthBloc: signOut success');
      emit(Unauthenticated());
    } catch (e, st) {
      // ignore: avoid_print
      print('AuthBloc: signOut failed -> $e\n$st');
      emit(AuthFailure(e.toString()));
    }
  }
}
