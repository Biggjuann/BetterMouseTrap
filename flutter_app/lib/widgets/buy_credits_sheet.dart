import 'package:flutter/material.dart';

import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';

class BuyCreditsSheet extends StatelessWidget {
  const BuyCreditsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = PurchaseService.instance.availablePacks;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mist.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            const Text(
              'Get More Credits',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Current balance
            ValueListenableBuilder<int>(
              valueListenable: CreditService.instance.balance,
              builder: (_, balance, __) => Text(
                'Current balance: $balance credits',
                style: TextStyle(
                  color: AppColors.mist,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Credit packs
            if (packs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Credit packs are loading or not available on this platform.',
                  style: TextStyle(color: AppColors.mist),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...packs.map((pack) => _CreditPackCard(pack: pack)),

            const SizedBox(height: AppSpacing.md),

            // Info note
            Text(
              'Each credit powers one Idea Generation or Patent Analysis.',
              style: TextStyle(color: AppColors.mist, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.base),

            // Error display
            ValueListenableBuilder<String?>(
              valueListenable: PurchaseService.instance.purchaseError,
              builder: (_, error, __) {
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    error,
                    style: TextStyle(color: AppColors.coral, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditPackCard extends StatelessWidget {
  final CreditPack pack;
  const _CreditPackCard({required this.pack});

  bool get _isBestValue => pack.credits >= 50;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ValueListenableBuilder<bool>(
        valueListenable: PurchaseService.instance.isPurchasing,
        builder: (_, isPurchasing, __) {
          return GestureDetector(
            onTap: isPurchasing
                ? null
                : () => PurchaseService.instance.buyCredits(pack),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: _isBestValue
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _isBestValue
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  width: _isBestValue ? 2 : 1,
                ),
                boxShadow: _isBestValue ? AppShadows.card : [],
              ),
              child: Row(
                children: [
                  // Credit count icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        '${pack.credits}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  // Description
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '${pack.credits} credits',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_isBestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: AppColors.teal,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Price button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPurchasing
                          ? AppColors.mist
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: isPurchasing ? [] : AppShadows.button,
                    ),
                    child: Text(
                      pack.price.isEmpty ? '...' : pack.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
