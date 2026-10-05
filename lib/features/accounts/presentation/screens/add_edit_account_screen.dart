import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_select_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/account.dart';
import '../providers/account_provider.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? initialAccount;
  final Account? account;

  const AddEditAccountScreen({
    super.key,
    this.initialAccount,
    this.account,
  });

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _selectedType;
  late int _selectedColor;
  bool _isSaving = false;
  bool _isDeleting = false;

  Account? get _targetAccount => widget.account ?? widget.initialAccount;

  @override
  void initState() {
    super.initState();
    final acc = _targetAccount;
    _nameController = TextEditingController(text: acc?.name ?? '');

    // For editing, get the current calculated balance from provider if available
    final accProvider = context.read<AccountProvider>();
    final found = accProvider.accountsWithBalances.where((a) => a.account.id == acc?.id).firstOrNull;
    final currentUnits = found?.calculatedBalance.units ?? acc?.openingBalance.units ?? 0;

    _balanceController = TextEditingController(
      text: acc != null ? (currentUnits / 100).toStringAsFixed(2) : '0.00',
    );
    _selectedType = acc?.accountType ?? AccountType.bank;
    _selectedColor = acc?.color ?? AppColors.categoryPalette.first.toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }

    final balanceParsed = Money.tryParse(_balanceController.text) ?? const Money.zero();

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final acc = _targetAccount;
      final provider = context.read<AccountProvider>();

      if (acc != null) {
        // Calculate new opening balance if current balance was modified
        final currentWithBal = provider.accountsWithBalances.where((a) => a.account.id == acc.id).firstOrNull;
        final currentUnits = currentWithBal?.calculatedBalance.units ?? acc.openingBalance.units;
        final diffUnits = balanceParsed.units - currentUnits;
        final updatedOpeningBalance = Money(
          units: acc.openingBalance.units + diffUnits,
          currencyCode: acc.currency,
        );

        final updatedAccount = Account(
          id: acc.id,
          name: name,
          accountType: _selectedType,
          openingBalance: updatedOpeningBalance,
          color: _selectedColor,
          isArchived: acc.isArchived,
          createdAt: acc.createdAt,
          updatedAt: now,
        );
        await provider.updateAccount(updatedAccount);
      } else {
        // Create new account
        final newAccount = Account(
          id: IdGenerator.uuid(),
          name: name,
          accountType: _selectedType,
          openingBalance: balanceParsed,
          color: _selectedColor,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        );
        await provider.createAccount(newAccount);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final acc = _targetAccount;
    if (acc == null) return;

    final provider = context.read<AccountProvider>();
    final settings = context.read<SettingsProvider>();

    // Calculate actual current balance from transaction history
    final withBal = await provider.getAccountWithBalance(acc.id);
    final balanceUnits = withBal?.calculatedBalance.units ?? 0;
    final isZeroBalance = balanceUnits == 0;
    final formattedBalance = (withBal?.calculatedBalance ?? const Money.zero()).format(currency: settings.currency);

    if (!mounted) return;

    bool? confirmed;

    if (isZeroBalance) {
      // Zero balance simple confirmation
      confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete ${acc.name}?'),
          content: const Text(
            'This account has a zero balance.\n\nHistorical transactions will be preserved.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    } else {
      // Non-zero balance warning confirmation
      confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete ${acc.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current balance:',
                style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                formattedBalance,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This account currently has a balance.\nDeleting the account will not delete its existing transactions.\n\nThe account will be removed from active account selection, while historical transaction data will be preserved.',
                style: TextStyle(fontSize: 13.5, height: 1.4),
              ),
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
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Proceed with Deletion'),
            ),
          ],
        ),
      );
    }

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await provider.deleteAccount(acc.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${acc.name}" deleted. Historical transactions preserved.'),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acc = _targetAccount;
    final activeColor = Color(_selectedColor);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          AppHeader(
            title: acc != null ? 'Edit Account' : 'Create Account',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Top: Selected color circle + Account Name field
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'ACCOUNT NAME',
                          controller: _nameController,
                          hintText: 'e.g. HDFC Bank, Cash, Savings',
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Balance Edit Section (Directly Editable)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc != null ? 'CURRENT BALANCE' : 'OPENING BALANCE',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              settingsProvider.currency.symbol,
                              style: AppTypography.displaySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _balanceController,
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
                              ),
                            ),
                            Text(
                              settingsProvider.currency.code,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Account Type Selector (Clean AppSelectField)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: AppSelectField<AccountType>(
                    label: 'ACCOUNT TYPE',
                    value: _selectedType,
                    searchable: false,
                    items: AccountType.values.map((t) {
                      return AppSelectItem<AccountType>(
                        value: t,
                        title: t.displayName,
                        icon: Icons.account_balance_wallet_outlined,
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Color Palette
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COLOR ACCENT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AppColors.categoryPalette.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final color = AppColors.categoryPalette[index];
                            final isSelected = color.toARGB32() == _selectedColor;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color.toARGB32()),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          acc != null ? 'Save Changes' : 'Create Account',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),

                // Delete Account Option (for existing accounts)
                if (acc != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _handleDeleteAccount,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                    label: _isDeleting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.expense))
                        : const Text(
                            'Delete Account',
                            style: TextStyle(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: AppColors.expense.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
