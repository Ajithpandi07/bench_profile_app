import 'package:bloc/bloc.dart';

/// Very small BlocObserver that prints events and transitions to console.
class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    // ignore: avoid_print
    print('BLOC EVENT: ${bloc.runtimeType} -> $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // ignore: avoid_print
    print('BLOC TRANSITION: ${bloc.runtimeType} -> $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    // ignore: avoid_print
    print('BLOC ERROR: ${bloc.runtimeType} -> $error');
  }
}
