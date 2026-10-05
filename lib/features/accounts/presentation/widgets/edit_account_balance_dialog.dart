import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/money.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/account.dart';
import '../providers/account_provider.dart';

class EditAccountBalanceDialog extends StatefulWidget {
  final AccountWithBalance accountWithBalance;

  const EditAccountBalanceDialog({
    super.key,
    required this.accountWithBalance,
  });

  static Future<bool?> show(BuildContext context, AccountWithBalance accountWithBalance) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAccountBalanceDialog(accountWithBalance: accountWithBalance),
    );
  }

  @override
  State<EditAccountBalanceDialog> createState() => _EditAccountBalanceDialogState();
}

class _EditAccountBalanceDialogState extends State<EditAccountBalanceDialog> {
  late TextEditingController _balanceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentUnits = widget.accountWithBalance.calculatedBalance.units;
    _balanceController = TextEditingController(
      text: (currentUnits / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Widget _buildConfirmRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    Account account,
    Money currentBalance,
    Money parsedNewBalance,
    int diffUnits,
    SettingsProvider settings,
    AccountProvider accountProvider,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (diffUnits != 0) {
      final isDiffPositive = diffUnits > 0;
      final diffText = '${isDiffPositive ? "+" : "-"}${Money.fromUnits(diffUnits.abs()).format(currency: settings.currency)}';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Update account balance?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmRow('Current:', currentBalance.format(currency: settings.currency)),
              const SizedBox(height: 8),
              _buildConfirmRow('New:', parsedNewBalance.format(currency: settings.currency)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              _buildConfirmRow('Difference:', diffText, isBold: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      if (diffUnits != 0) {
        await accountProvider.adjustAccountBalance(
          accountId: account.id,
          newBalance: parsedNewBalance,
        );
      }
      if (mounted) {
        navigator.pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Account balance updated to ${parsedNewBalance.format(currency: settings.currency)}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error updating balance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accountProvider = context.read<AccountProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final acc = widget.accountWithBalance.account;
    final currentBalance = widget.accountWithBalance.calculatedBalance;
    final parsedNewBalance = Money.tryParse(_balanceController.text) ?? currentBalance;
    final diffUnits = parsedNewBalance.units - currentBalance.units;
    final isDiffPositive = diffUnits > 0;
    final isDiffZero = diffUnits == 0;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Account Info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(acc.color ?? AppColors.primary.toARGB32()).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  acc.iconData,
                  color: Color(acc.color ?? AppColors.primary.toARGB32()),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Current Balance',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${acc.name} • ${acc.accountType.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Current Balance Display Box
          Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            child: Text(
              currentBalance.format(currency: settings.currency),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // New Balance Input Field
          Text(
            'New Balance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  settings.currency.symbol,
                  style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _balanceController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: AppTypography.displaySmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Text(
                  settings.currency.code,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Informational Difference Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Difference: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    isDiffZero
                        ? '${settings.currency.symbol}0.00'
                        : '${isDiffPositive ? "+" : "-"}${Money.fromUnits(diffUnits.abs()).format(currency: settings.currency)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Action Buttons: Cancel and Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _handleSave(
                            context,
                            acc,
                            currentBalance,
                            parsedNewBalance,
                            diffUnits,
                            settings,
                            accountProvider,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
