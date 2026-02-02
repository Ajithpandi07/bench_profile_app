import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserProfileRepository repository;

  UserProfileBloc({required this.repository}) : super(UserProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(UserProfileLoading());
    // ignore: avoid_print
    print('DEBUG UserProfileBloc: Loading profile...');
    final result = await repository.getUserProfile();
    result.fold(
      (failure) {
        // ignore: avoid_print
        print('DEBUG UserProfileBloc: Failed to load: ${failure.message}');
        emit(UserProfileError(failure.message));
      },
      (profile) {
        // ignore: avoid_print
        print(
          'DEBUG UserProfileBloc: Loaded success. TargetCals: ${profile.targetCalories}, TargetWater: ${profile.targetWater}',
        );
        emit(UserProfileLoaded(profile));
      },
    );
  }
}
