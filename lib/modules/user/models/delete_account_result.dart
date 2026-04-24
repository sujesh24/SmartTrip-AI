enum DeleteAccountStatus { success, requiresRecentLogin, noUser, failure }

class DeleteAccountResult {
  const DeleteAccountResult._(this.status, {this.message});

  final DeleteAccountStatus status;
  final String? message;

  bool get isSuccess => status == DeleteAccountStatus.success;
  bool get requiresRecentLogin =>
      status == DeleteAccountStatus.requiresRecentLogin;
  bool get hasNoUser => status == DeleteAccountStatus.noUser;

  factory DeleteAccountResult.success() {
    return const DeleteAccountResult._(DeleteAccountStatus.success);
  }

  factory DeleteAccountResult.requiresRecentLogin({String? message}) {
    return DeleteAccountResult._(
      DeleteAccountStatus.requiresRecentLogin,
      message: message,
    );
  }

  factory DeleteAccountResult.noUser({String? message}) {
    return DeleteAccountResult._(DeleteAccountStatus.noUser, message: message);
  }

  factory DeleteAccountResult.failure(String message) {
    return DeleteAccountResult._(DeleteAccountStatus.failure, message: message);
  }
}
