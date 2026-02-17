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

  /// Counts for diagnostics.
  int _staleCleared = 0;
  int _streamEvents = 0;

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

    // Phase 1: Attach listener to capture stale transactions.
    // Any purchased/restored transactions that arrive before _ready=true
    // are stale and will be completed immediately (no backend call).
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => purchaseError.value = 'Stream error: $e',
    );

    // Give StoreKit a moment to deliver any stale transactions
    await Future.delayed(const Duration(milliseconds: 1500));

    // Phase 2: Mark as ready — future stream events are real purchases.
    _ready = true;

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

    if (_staleCleared > 0) {
      purchaseError.value =
          'DIAG: cleared $_staleCleared stale txn(s). Ready for purchases.';
    }
  }

  Future<void> buyCredits(CreditPack pack) async {
    if (pack.storeProduct == null) {
      purchaseError.value = 'DIAG: storeProduct is null for ${pack.productId}';
      return;
    }
    if (!_ready) {
      purchaseError.value = 'DIAG: still initializing, please wait...';
      return;
    }

    isPurchasing.value = true;
    purchaseError.value = 'DIAG: calling buyConsumable...';

    try {
      final purchaseParam = PurchaseParam(productDetails: pack.storeProduct!);
      final started = await _iap.buyConsumable(purchaseParam: purchaseParam);
      if (!started) {
        isPurchasing.value = false;
        purchaseError.value =
            'DIAG: buyConsumable=false (cleared=$_staleCleared)';
      } else {
        purchaseError.value =
            'DIAG: buyConsumable=true, waiting for StoreKit dialog...';
      }
    } catch (e) {
      isPurchasing.value = false;
      purchaseError.value = 'DIAG: buyConsumable threw: $e';
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      _streamEvents++;
      final pid = purchase.purchaseID ?? 'no-id';

      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          purchaseError.value = 'DIAG: #$_streamEvents pending id=$pid';
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!_ready) {
            // STALE: arrived during init — complete immediately, no backend call
            _staleCleared++;
            _completedIds.add(pid);
            purchaseError.value =
                'DIAG: clearing stale #$_staleCleared id=$pid';
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          } else if (_completedIds.contains(pid)) {
            // Already processed this exact transaction
            purchaseError.value =
                'DIAG: #$_streamEvents re-skip id=$pid';
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          } else {
            // REAL purchase after user tap
            purchaseError.value =
                'DIAG: #$_streamEvents verifying id=$pid...';
            await _verifyAndComplete(purchase);
          }
          break;

        case PurchaseStatus.error:
          isPurchasing.value = false;
          purchaseError.value =
              'DIAG: #$_streamEvents error=${purchase.error?.message} id=$pid';
          try {
            await _iap.completePurchase(purchase);
          } catch (_) {}
          break;

        case PurchaseStatus.canceled:
          isPurchasing.value = false;
          purchaseError.value = 'DIAG: #$_streamEvents canceled id=$pid';
          try {
            await _iap.completePurchase(purchase);
          } catch (_) {}
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
      _completedIds.add(pid);

      isPurchasing.value = false;
      if (granted > 0) {
        purchaseError.value =
            'DIAG: +$granted credits! balance=$newBalance';
      } else {
        purchaseError.value =
            'DIAG: granted=0 id=$pid (already processed). Tap again.';
      }
    } catch (e) {
      isPurchasing.value = false;
      purchaseError.value = 'DIAG: verify error id=$pid — $e';
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
