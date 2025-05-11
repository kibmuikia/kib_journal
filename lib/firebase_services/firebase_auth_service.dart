import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, User, UserCredential;
import 'package:kib_journal/core/errors/exceptions.dart' show ExceptionX;
import 'package:kib_utils/kib_utils.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  bool get isSignedIn => currentUser != null;

  Future<Result<UserCredential, Exception>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await tryResultAsync<UserCredential, Exception>(() async {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }, (err) => _handleAuthError(err, 'Error during email/password sign up'));
  }

  Future<Result<UserCredential, Exception>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await tryResultAsync<UserCredential, Exception>(() async {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }, (err) => _handleAuthError(err, 'Error during email/password sign in'));
  }

  Future<Result<void, Exception>> signOut() async {
    return await tryResultAsync<void, Exception>(() async {
      await _firebaseAuth.signOut();
    }, (err) => _handleAuthError(err, 'Error during sign out'));
  }

  Future<Result<void, Exception>> sendPasswordResetEmail({
    required String email,
  }) async {
    return await tryResultAsync<void, Exception>(() async {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    }, (err) => _handleAuthError(err, 'Error sending password reset email'));
  }

  Exception _handleAuthError(dynamic err, String messagePrefix) {
    if (err is FirebaseAuthException) {
      return ExceptionX(
        message: '$messagePrefix: ${err.message ?? err.code}',
        errorType: err.runtimeType,
        error: err,
        stackTrace: StackTrace.current,
      );
    }

    return err is Exception
        ? err
        : ExceptionX(
          message: '$messagePrefix: ${err.toString()}',
          errorType: err.runtimeType,
          error: err,
          stackTrace: StackTrace.current,
        );
  }
}
