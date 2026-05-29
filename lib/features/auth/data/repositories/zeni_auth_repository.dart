class ZeniAuthUser {
  const ZeniAuthUser({required this.id, this.email});

  final String id;
  final String? email;
}

class ZeniAuthOperationResult {
  const ZeniAuthOperationResult({
    required this.isSuccess,
    this.user,
    this.message,
    this.requiresEmailConfirmation = false,
  });

  const ZeniAuthOperationResult.success({
    ZeniAuthUser? user,
    String? message,
  }) : this(isSuccess: true, user: user, message: message);

  const ZeniAuthOperationResult.pendingEmailConfirmation({
    ZeniAuthUser? user,
    String? message,
  }) : this(
         isSuccess: true,
         user: user,
         message: message,
         requiresEmailConfirmation: true,
       );

  const ZeniAuthOperationResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final ZeniAuthUser? user;
  final String? message;
  final bool requiresEmailConfirmation;
}

abstract class ZeniAuthRepository {
  ZeniAuthUser? get currentUser;

  Stream<ZeniAuthUser?> authStateChanges();

  bool get isGoogleSignInAvailable;
  bool get isAppleSignInAvailable;

  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<ZeniAuthOperationResult> signInWithGoogle();

  Future<ZeniAuthOperationResult> signInWithApple();

  Future<ZeniAuthOperationResult> signOut();
}
