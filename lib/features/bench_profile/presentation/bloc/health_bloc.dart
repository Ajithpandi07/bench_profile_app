import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/fetch_health_data.dart';
import '../../domain/usecases/upload_health_data.dart';
import 'health_event.dart';
import 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final FetchHealthData fetchHealthData;
  final UploadHealthData uploadHealthData;
  final String? Function()? _getCurrentUid;

  HealthBloc({
    required this.fetchHealthData,
    required this.uploadHealthData,
    String? Function()? getCurrentUid,
  }) :
        _getCurrentUid = getCurrentUid,
        super(HealthInitial()) {
    on<FetchHealthRequested>(_onFetch);
    on<UploadHealthRequested>(_onUpload);
  }

  Future<void> _onFetch(FetchHealthRequested event, Emitter<HealthState> emit) async {
    emit(HealthLoading());
    try {
      final result  = await fetchHealthData(NoParams());
      result.fold(
        (f) => emit(HealthFailure(f.message)),
        (m) async {
          emit(HealthLoaded(m));
          // after loading metrics, if a user is signed in try to upload
          String? uid;
          if (_getCurrentUid != null) {
            uid = _getCurrentUid();
          } else {
            uid = FirebaseAuth.instance.currentUser?.uid;
          }
          if (uid != null) {
            // dispatch an upload event so UI can react to upload states
            add(UploadHealthRequested(uid: uid, metrics: m));
          }
        },
      );
    } catch (e) {
      emit(HealthFailure(e.toString()));
    }
  }

  Future<void> _onUpload(UploadHealthRequested event, Emitter<HealthState> emit) async {
    emit(HealthUploadInProgress());
    try {
      final res = await uploadHealthData(UploadHealthDataParams(
        uid: event.uid,
        metrics: event.metrics,
      ));
      res.fold((f) => emit(HealthUploadFailure(f.message)), (_) => emit(HealthUploadSuccess()));
    } catch (e) {
      emit(HealthUploadFailure(e.toString()));
    }
  }
}
