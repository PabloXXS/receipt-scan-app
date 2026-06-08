/// Назначение: базовый тип ошибок домена и маппинг исключений.
///
/// Слой: core/error
/// Зависимости: нет.
/// Ключевые типы: Failure.
library;

/// Базовая ошибка прикладного уровня.
sealed class Failure {
  const Failure(this.message);

  /// Человекочитаемое сообщение об ошибке.
  final String message;
}

/// Непредвиденная ошибка.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
