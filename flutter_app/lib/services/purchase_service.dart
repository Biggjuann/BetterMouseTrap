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

  /// Set of purchaseIDs already seen/completed to avoid reprocessing.
  final Set<String> _completedIds = {};

  /// Tracks total stream events for diagnostics.
  int _streamEventCount = 0;

  /// True when we're waiting for a fresh purchase after buyConsumable.
  bool _awaitingNewPurchase = false;

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
    final available = await _iap.isAvailable();
    if (!available) {
      purchaseError.value = 'DIAG: IAP not available on this device';
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => purchaseError.value = 'Stream error: $e',
    );

    final response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      purchaseError.value =
          'DIAG: Products not found: ${response.notFoundIDs.join(", ")}';
    }

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
    if (pack.storeProduct == null) {
      purchaseError.value = 'DIAG: storeProduct is null for ${pack.productId}';
      return;
    }
    isPurchasing.value = true;
    purchaseError.value = 'DIAG: calling buyConsumable...';
    _awaitingNewPurchase = true;

    try {
      final purchaseParam = PurchaseParam(productDetails: pack.storeProduct!);
      final started = await _iap.buyConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _awaitingNewPurchase = false;
        isPurchasing.value = false;
        purchaseError.value =
            'DIAG: buyConsumable=false (seen=${_completedIds.length} txns)';
      } else {
        purchaseError.value =
            'DIAG: buyConsumable=true, waiting for StoreKit...';
      }
    } catch (e) {
      _awaitingNewPurchase = false;
      isPurchasing.value = false;
      purchaseError.value = 'DIAG: buyConsumable threw: $e';
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      _streamEventCount++;
      final pid = purchase.purchaseID ?? 'no-id';

      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          purchaseError.value =
              'DIAG: #$_streamEventCount pending id=$pid';
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Skip if we already processed this exact transaction
          if (_completedIds.contains(pid)) {
            purchaseError.value =
                'DIAG: #$_streamEventCount SKIP duplicate id=$pid';
            // Still complete it to clear the queue
            await _iap.completePurchase(purchase);
            break;
          }

          // Always verify with backend and always complete
          purchaseError.value =
              'DIAG: #$_streamEventCount verifying id=$pid...';
          await _verifyAndComplete(purchase);
          break;

        case PurchaseStatus.error:
          _awaitingNewPurchase = false;
          isPurchasing.value = false;
          purchaseError.value =
              'DIAG: #$_streamEventCount error=${purchase.error?.message} id=$pid';
          await _iap.completePurchase(purchase);
          break;

        case PurchaseStatus.canceled:
          _awaitingNewPurchase = false;
          isPurchasing.value = false;
          purchaseError.value =
              'DIAG: #$_streamEventCount canceled id=$pid';
          await _iap.completePurchase(purchase);
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final pid = purchase.purchaseID ?? 'no-id';

    try {
      final result = await ApiClient.instance.verifyPurchase(
        transactionId: pid,
        productId: purchase.productID,
        signedTransaction: purchase.verificationData.serverVerificationData,
      );

      final granted = result['credits_granted'] as int;
      final newBalance = result['new_balance'] as int;
      CreditService.instance.balance.value = newBalance;

      // Mark this transaction as processed
      _completedIds.add(pid);

      if (granted > 0) {
        // Real new purchase — success!
        _awaitingNewPurchase = false;
        isPurchasing.value = false;
        purchaseError.value =
            'DIAG: +$granted credits! balance=$newBalance (id=$pid)';
      } else {
        // Duplicate / already-granted transaction
        purchaseError.value =
            'DIAG: dup txn id=$pid (granted=0). '
            '${_awaitingNewPurchase ? "Still waiting for new purchase..." : ""}';
        // If not awaiting a new purchase, reset state
        if (!_awaitingNewPurchase) {
          isPurchasing.value = false;
        }
        // If awaiting, keep isPurchasing=true — the real purchase is coming
      }
    } catch (e) {
      _awaitingNewPurchase = false;
      isPurchasing.value = false;
      purchaseError.value = 'DIAG: verify error id=$pid — $e';
    } finally {
      // Always complete — don't check pendingCompletePurchase
      // to ensure stale transactions are truly cleared
      try {
        await _iap.completePurchase(purchase);
      } catch (_) {
        // completePurchase can throw if already completed
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
