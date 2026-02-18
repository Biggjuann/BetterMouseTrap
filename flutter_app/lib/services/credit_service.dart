import 'package:flutter/foundation.dart';

import 'api_client.dart';

class CreditService {
  static final CreditService instance = CreditService._();
  CreditService._();

  final ValueNotifier<int> balance = ValueNotifier<int>(0);
  final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);

  bool get hasCredits => isAdmin.value || balance.value > 0;

  bool hasCreditsFor(int amount) => isAdmin.value || balance.value >= amount;

  /// Fetch balance from server.
  Future<void> refresh() async {
    try {
      final data = await ApiClient.instance.getCreditBalance();
      balance.value = data['balance'] as int;
      isAdmin.value = data['is_admin'] as bool;
    } catch (_) {
      // Silently fail — stale balance is acceptable
    }
  }

  /// Locally decrement after a successful paid API call.
  void localDeduct([int amount = 1]) {
    if (!isAdmin.value) {
      balance.value = (balance.value - amount).clamp(0, 999999);
    }
  }

  void reset() {
    balance.value = 0;
    isAdmin.value = false;
  }
}
