/// A lightweight UseCase contract: input Params, output Future<Result>.
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

class NoParams {}
