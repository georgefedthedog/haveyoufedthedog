import '../../l10n/l10n.dart';

/// Localizes a custom-hook error body. Since the i18n release the hooks
/// return a stable `code` (plus params like streak/threshold) alongside
/// their unchanged English `message`; known codes render from the ARB,
/// anything else - PB core errors, or codes newer than this build - falls
/// back to the raw message, then to [fallback].
String serverMessage(
  AppLocalizations l10n,
  Map<String, dynamic> response, {
  required String fallback,
}) {
  switch (response['code']) {
    case 'not_signed_in':
      return l10n.serverNotSignedIn;
    case 'not_member':
      return l10n.serverNotMember;
    case 'owner_only':
      return l10n.serverOwnerOnly;
    case 'name_required':
      return l10n.serverNameRequired;
    case 'password_too_short':
      return l10n.serverPasswordTooShort;
    case 'claim_code_invalid':
      return l10n.serverClaimCodeInvalid;
    case 'email_in_use':
      return l10n.serverEmailInUse;
    case 'no_such_member':
    case 'no_such_managed_member':
      return l10n.serverNoSuchMember;
    case 'invite_code_invalid':
      return l10n.serverInviteCodeInvalid;
    case 'pack_code_invalid':
      return l10n.serverPackCodeInvalid;
    case 'pack_gone':
      return l10n.serverPackGone;
    case 'unknown_product':
      return l10n.serverUnknownProduct;
    case 'verify_failed':
      return l10n.serverVerifyFailed;
    case 'verify_unavailable':
      return l10n.serverVerifyUnavailable;
    case 'reward_unavailable':
      return l10n.serverRewardUnavailable;
    case 'streak_check_failed':
      return l10n.serverStreakCheckFailed;
    case 'streak_too_low':
      final streak = (response['streak'] as num?)?.toInt();
      final threshold = (response['threshold'] as num?)?.toInt();
      if (streak != null && threshold != null) {
        return l10n.serverStreakTooLow(threshold, streak);
      }
  }
  return response['message'] as String? ?? fallback;
}
