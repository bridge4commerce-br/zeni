class ZeniAuthUser {
  const ZeniAuthUser({required this.id, this.email, this.displayName});

  final String id;
  final String? email;
  final String? displayName;
}

enum ZeniAuthIssue { localFamilyConflict }

const localFamilyConflictTitle = 'Este aparelho tem dados antigos';
const localFamilyConflictMessage =
    'Esta família foi criada antes de ser vinculada a uma conta. '
    'Para evitar misturar informações, o Zeni não vai conectá-la automaticamente.';

class ZeniAuthOperationResult {
  const ZeniAuthOperationResult({
    required this.isSuccess,
    this.user,
    this.message,
    this.requiresEmailConfirmation = false,
    this.issue,
  });

  const ZeniAuthOperationResult.success({ZeniAuthUser? user, String? message})
    : this(isSuccess: true, user: user, message: message);

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

  const ZeniAuthOperationResult.localFamilyConflict({ZeniAuthUser? user})
    : this(
        isSuccess: false,
        user: user,
        message: localFamilyConflictMessage,
        issue: ZeniAuthIssue.localFamilyConflict,
      );

  final bool isSuccess;
  final ZeniAuthUser? user;
  final String? message;
  final bool requiresEmailConfirmation;
  final ZeniAuthIssue? issue;
}

abstract class ZeniAuthRepository {
  ZeniAuthUser? get currentUser;

  Stream<ZeniAuthUser?> authStateChanges();

  bool get isGoogleSignInAvailable;
  bool get isAppleSignInAvailable;

  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String displayName,
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
