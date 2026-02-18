import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_client.dart';
import 'credit_service.dart';

class CreditPack {
  final String productId;
  final int credits;
  final String price;
  final ProductDetails? storeProduct;

  CreditPack({
    required this.productId,
    required this.credits,
    this.price = '',
    this.storeProduct,
  });
}

class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final ValueNotifier<bool> isPurchasing = ValueNotifier<bool>(false);
  final ValueNotifier<String?> purchaseError = ValueNotifier<String?>(null);

  /// Set of purchaseIDs already completed to skip duplicates.
  final Set<String> _completedIds = {};

  /// True once init has finished clearing stale transactions.
  bool _ready = false;

  static const _productIds = {
    'com.mousetrap.credits.10',
    'com.mousetrap.credits.25',
    'com.mousetrap.credits.50',
  };

  static const _creditAmounts = {
    'com.mousetrap.credits.10': 10,
    'com.mousetrap.credits.25': 25,
    'com.mousetrap.credits.50': 50,
  };

  List<CreditPack> availablePacks = [];

  Future<void> init() async {
    if (!await _iap.isAvailable()) return;

    // Phase 1: Attach listener to capture stale transactions.
    // Any purchased/restored transactions that arrive before _ready=true
    // are stale and will be completed immediately (no backend call).
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => purchaseError.value = e.toString(),
    );

    // Give StoreKit a moment to deliver any stale transactions
    await Future.delayed(const Duration(milliseconds: 1500));

    // Phase 2: Mark as ready — future stream events are real purchases.
    _ready = true;

    final response = await _iap.queryProductDetails(_productIds);
    availablePacks = response.productDetails.map((p) {
      return CreditPack(
        productId: p.id,
        credits: _creditAmounts[p.id] ?? 0,
        price: p.price,
        storeProduct: p,
      );
    }).toList()
      ..sort((a, b) => a.credits.compareTo(b.credits));
  }

  Future<void> buyCredits(CreditPack pack) async {
    if (pack.storeProduct == null) return;
    if (!_ready) return;

    isPurchasing.value = true;
    purchaseError.value = null;

    try {
      final purchaseParam = PurchaseParam(productDetails: pack.storeProduct!);
      final started = await _iap.buyConsumable(purchaseParam: purchaseParam);
      if (!started) {
        isPurchasing.value = false;
        purchaseError.value = 'Could not start purchase. Please try again.';
      }
    } catch (e) {
      isPurchasing.value = false;
      purchaseError.value = 'Purchase failed: $e';
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final pid = purchase.purchaseID ?? '';

      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!_ready || _completedIds.contains(pid)) {
            // Stale or already-processed transaction — just complete it
            _completedIds.add(pid);
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          } else {
            // Real purchase after user tap
            await _verifyAndComplete(purchase);
          }
          break;

        case PurchaseStatus.error:
          isPurchasing.value = false;
          purchaseError.value = purchase.error?.message ?? 'Purchase failed';
          try {
            await _iap.completePurchase(purchase);
          } catch (_) {}
          break;

        case PurchaseStatus.canceled:
          isPurchasing.value = false;
          try {
            await _iap.completePurchase(purchase);
          } catch (_) {}
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final pid = purchase.purchaseID ?? '';

    try {
      final result = await ApiClient.instance.verifyPurchase(
        transactionId: pid,
        productId: purchase.productID,
        signedTransaction: purchase.verificationData.serverVerificationData,
      );

      final newBalance = result['new_balance'] as int;
      CreditService.instance.balance.value = newBalance;
      _completedIds.add(pid);

      isPurchasing.value = false;
      purchaseError.value = null;
    } catch (e) {
      isPurchasing.value = false;
      purchaseError.value = 'Verification failed: $e';
    } finally {
      try {
        await _iap.completePurchase(purchase);
      } catch (_) {}
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
