import 'package:flutter/material.dart';

import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import 'studio_widgets.dart';

// Editorial Studio: the credit sheet reads as a small subscription
// card rather than a neon upsell. Mono labels, serif number, ink
// primary CTA, accent-soft best-value wash.

class BuyCreditsSheet extends StatelessWidget {
  const BuyCreditsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = PurchaseService.instance.availablePacks;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppColors.hairline),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.mist.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(width: 20, height: 2, color: AppColors.accentInk),
                const SizedBox(width: 10),
                Text('THE REFILL', style: AppText.monoMeta),
              ],
            ),
            const SizedBox(height: 10),
            Text('Top up your ', style: AppText.display2),
            Text(
              'credits.',
              style: AppText.display2.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.accentInk,
              ),
            ),
            const SizedBox(height: 10),

            ValueListenableBuilder<int>(
              valueListenable: CreditService.instance.balance,
              builder: (_, balance, __) => Text(
                'Balance on file · $balance credits',
                style: AppText.monoMeta,
              ),
            ),
            const SizedBox(height: 18),

            if (packs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Credit packs are loading or unavailable on this platform.',
                  style: AppText.body.copyWith(
                    color: AppColors.graphite, fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...packs.map((pack) => _CreditPackRow(pack: pack)),

            const SizedBox(height: 14),
            Text(
              'One credit · one idea generation or patent search.',
              style: AppText.monoMeta,
            ),

            ValueListenableBuilder<String?>(
              valueListenable: PurchaseService.instance.purchaseError,
              builder: (_, error, __) {
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error,
                    style: AppText.caption.copyWith(
                      color: AppColors.warm, fontStyle: FontStyle.italic,
                    ),
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

class _CreditPackRow extends StatelessWidget {
  final CreditPack pack;
  const _CreditPackRow({required this.pack});

  bool get _isBestValue => pack.credits >= 50;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ValueListenableBuilder<bool>(
        valueListenable: PurchaseService.instance.isPurchasing,
        builder: (_, isPurchasing, __) {
          return InkWell(
            onTap: isPurchasing ? null : () => PurchaseService.instance.buyCredits(pack),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: _isBestValue ? AppColors.accentSoft : AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: _isBestValue ? AppColors.accentInk : AppColors.hairline,
                  width: _isBestValue ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Serif number
                  SizedBox(
                    width: 54,
                    child: Text(
                      '${pack.credits}',
                      style: TextStyle(
                        fontFamily: fontDisplay,
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CREDITS', style: AppText.monoMeta),
                        const SizedBox(height: 4),
                        if (_isBestValue)
                          Text(
                            'Best value',
                            style: AppText.body.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.accentInk,
                            ),
                          )
                        else
                          Text('Pay as you go', style: AppText.caption),
                      ],
                    ),
                  ),
                  // Price
                  StudioButton(
                    label: pack.price.isEmpty ? '…' : pack.price,
                    kind: _isBestValue ? BtnKind.primary : BtnKind.ghost,
                    onPressed: isPurchasing ? null : () => PurchaseService.instance.buyCredits(pack),
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
