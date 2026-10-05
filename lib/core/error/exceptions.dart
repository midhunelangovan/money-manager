class AppException implements Exception {
  final String message;
  final dynamic technicalDetails;

  const AppException(this.message, [this.technicalDetails]);

  @override
  String toString() => 'AppException: $message ${technicalDetails != null ? '($technicalDetails)' : ''}';
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.technicalDetails]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.technicalDetails]);
}

class BackupException extends AppException {
  const BackupException(super.message, [super.technicalDetails]);
}

class RestoreException extends AppException {
  const RestoreException(super.message, [super.technicalDetails]);
}

class IntegrityException extends AppException {
  const IntegrityException(super.message, [super.technicalDetails]);
}
