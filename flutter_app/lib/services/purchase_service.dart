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

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => purchaseError.value = e.toString(),
    );

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
    isPurchasing.value = true;
    purchaseError.value = null;

    final purchaseParam = PurchaseParam(productDetails: pack.storeProduct!);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(purchase);
          break;

        case PurchaseStatus.error:
          isPurchasing.value = false;
          purchaseError.value = purchase.error?.message ?? 'Purchase failed';
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          isPurchasing.value = false;
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    try {
      final result = await ApiClient.instance.verifyPurchase(
        transactionId: purchase.purchaseID ?? '',
        productId: purchase.productID,
        signedTransaction: purchase.verificationData.serverVerificationData,
      );

      final newBalance = result['new_balance'] as int;
      CreditService.instance.balance.value = newBalance;

      isPurchasing.value = false;
      purchaseError.value = null;
    } catch (e) {
      isPurchasing.value = false;
      purchaseError.value = 'Verification failed: $e';
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
