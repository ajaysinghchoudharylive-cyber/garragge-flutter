abstract class DataState<T> {
  const DataState();
}

class Success<T> extends DataState<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends DataState<T> {
  final Exception exception;
  const Failure(this.exception);
}
