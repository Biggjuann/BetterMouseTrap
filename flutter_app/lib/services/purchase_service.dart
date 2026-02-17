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

  /// True only after the user taps a pack. False during init when
  /// StoreKit replays old unfinished transactions.
  bool _userInitiated = false;

  /// Count of stale transactions completed on init.
  int _staleCompleted = 0;

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

    // Listener picks up pending (stale) transactions immediately.
    // _userInitiated is false, so they'll be completed without verification.
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

    // Mark as user-initiated so stream handler verifies with backend
    _userInitiated = true;

    try {
      final purchaseParam = PurchaseParam(productDetails: pack.storeProduct!);
      final started = await _iap.buyConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _userInitiated = false;
        isPurchasing.value = false;
        purchaseError.value =
            'DIAG: buyConsumable returned false (staleCompleted=$_staleCompleted)';
      } else {
        purchaseError.value =
            'DIAG: buyConsumable=true, waiting for StoreKit...';
      }
    } catch (e) {
      _userInitiated = false;
      isPurchasing.value = false;
      purchaseError.value = 'DIAG: buyConsumable threw: $e';
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final diag =
          'status=${purchase.status}, product=${purchase.productID}, '
          'id=${purchase.purchaseID}, pending=${purchase.pendingCompletePurchase}';

      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          purchaseError.value = 'DIAG: stream pending — $diag';
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_userInitiated) {
            // User-initiated purchase — verify with backend
            purchaseError.value =
                'DIAG: stream ${purchase.status} — verifying with server...';
            await _verifyAndComplete(purchase);
          } else {
            // Stale transaction from previous session — just complete it
            _staleCompleted++;
            purchaseError.value =
                'DIAG: completing stale txn #$_staleCompleted (${purchase.productID})';
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
          break;

        case PurchaseStatus.error:
          _userInitiated = false;
          isPurchasing.value = false;
          purchaseError.value =
              'DIAG: stream error — ${purchase.error?.message} | $diag';
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _userInitiated = false;
          isPurchasing.value = false;
          purchaseError.value = 'DIAG: stream canceled — $diag';
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    try {
      purchaseError.value = 'DIAG: calling verifyPurchase API...';
      final result = await ApiClient.instance.verifyPurchase(
        transactionId: purchase.purchaseID ?? '',
        productId: purchase.productID,
        signedTransaction: purchase.verificationData.serverVerificationData,
      );

      final granted = result['credits_granted'] as int;
      final newBalance = result['new_balance'] as int;
      CreditService.instance.balance.value = newBalance;

      _userInitiated = false;
      isPurchasing.value = false;
      purchaseError.value =
          'DIAG: success! granted=$granted, balance=$newBalance';
    } catch (e) {
      _userInitiated = false;
      isPurchasing.value = false;
      purchaseError.value = 'DIAG: verify error — $e';
    } finally {
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
