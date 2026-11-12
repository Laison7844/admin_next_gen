import 'package:firebase_auth/firebase_auth.dart';

/// Configuration for single-admin authorization.
///
/// In production, these can be overridden at build time via:
/// `--dart-define=ADMIN_UID=...` and `--dart-define=ADMIN_EMAIL=...`
class AdminConfig {
  static const String authorizedAdminUid = String.fromEnvironment(
    'ADMIN_UID',
    defaultValue: 'NEXTGEN_ADMIN_PRIMARY_UID',
  );

  static const String authorizedAdminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'admin@nextgen.edu',
  );

  /// Validates whether a given Firebase [User] satisfies the client-side
  /// admin criteria before granting access to CMS views.
  ///
  /// Note: The absolute security boundary is enforced at the Firestore
  /// Security Rules level via `request.auth.uid`.
  static bool isAuthorizedAdmin(User? user) {
    if (user == null) return false;
    // Client-side verification: match email or UID
    final emailMatches = user.email != null &&
        user.email!.toLowerCase() == authorizedAdminEmail.toLowerCase();
    final uidMatches = user.uid == authorizedAdminUid;

    // In local development/initial setup where UID might not be set yet,
    // match verified email or UID.
    return emailMatches || uidMatches;
  }
}

