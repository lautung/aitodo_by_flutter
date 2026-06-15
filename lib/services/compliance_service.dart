import 'package:shared_preferences/shared_preferences.dart';

class ComplianceService {
  static const String agreementAcceptedKey = 'agreement_accepted_v1';

  const ComplianceService();

  Future<bool> hasAcceptedAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(agreementAcceptedKey) ?? false;
  }

  Future<void> acceptAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(agreementAcceptedKey, true);
  }
}
