/// Base class for all domain-level failures with user-friendly messages.
abstract class Failure {
  final String message;
  final String? technicalDetails;

  const Failure(this.message, {this.technicalDetails});

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.technicalDetails});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.technicalDetails});
}

class BackupRestoreFailure extends Failure {
  const BackupRestoreFailure(super.message, {super.technicalDetails});
}

class IntegrityCheckFailure extends Failure {
  const IntegrityCheckFailure(super.message, {super.technicalDetails});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.technicalDetails});
}
