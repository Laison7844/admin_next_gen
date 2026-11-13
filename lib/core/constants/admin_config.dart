import 'package:firebase_auth/firebase_auth.dart';

/// Configuration for single-admin authorization.
///
/// Anchored to the explicit Firebase Authentication UID matching
/// the authorization boundary in Firestore Security Rules.
class AdminConfig {
  static const String authorizedAdminUid = String.fromEnvironment(
    'ADMIN_UID',
    defaultValue: 'p6awFfdX9jRKAScGwvSU9OMXjm72',
  );

  static const String authorizedAdminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'admin@nextgen.edu',
  );

  /// Validates whether a given Firebase [User] satisfies the single-admin
  /// criteria based strictly on the authorized admin UID.
  static bool isAuthorizedAdmin(User? user) {
    if (user == null) return false;
    return user.uid == authorizedAdminUid;
  }
}
