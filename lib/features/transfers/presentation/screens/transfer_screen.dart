import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/transfer.dart';
import '../providers/transfer_provider.dart';

class TransferScreen extends StatefulWidget {
  final String? initialFromAccountId;

  const TransferScreen({
    super.key,
    this.initialFromAccountId,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String? _fromAccountId;
  String? _toAccountId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fromAccountId = widget.initialFromAccountId;
    final accountProvider = context.read<AccountProvider>();
    final activeAccounts = accountProvider.accountsWithBalances.where((a) => !a.account.isArchived).toList();

    if (_fromAccountId == null && activeAccounts.isNotEmpty) {
      _fromAccountId = activeAccounts.first.account.id;
    }

    // Preselect a different destination account if available
    if (activeAccounts.length > 1) {
      final other = activeAccounts.where((a) => a.account.id != _fromAccountId).firstOrNull;
      if (other != null) {
        _toAccountId = other.account.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _saveTransfer() async {
    if (_fromAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source account.')),
      );
      return;
    }

    if (_toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account.')),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts cannot be the same.')),
      );
      return;
    }

    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount greater than 0.')),
      );
      return;
    }

    final transferMoney = Money(units: (parsedAmount * 100).round());

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final transfer = Transfer(
        id: IdGenerator.generate(),
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: transferMoney,
        date: _date,
        description: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : 'Account Transfer',
        createdAt: now,
        updatedAt: now,
      );

      final transferProvider = context.read<TransferProvider>();
      final accountProvider = context.read<AccountProvider>();
      final txProvider = context.read<TransactionProvider>();

      await transferProvider.createTransfer(transfer);
      await accountProvider.loadAccounts();
      await txProvider.loadLedger();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transfer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeAccounts = accountProvider.accountsWithBalances
        .where((a) => !a.account.isArchived)
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // Header
          const AppHeader(
            showBackButton: true,
            title: 'Transfer',
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Transfer Route Card: From -> To
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // From Account Dropdown
                      Text(
                        'FROM ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fromAccountId,
                            isExpanded: true,
                            hint: const Text('Select Source Account'),
                            dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                            items: activeAccounts.map((acc) {
                              final color = acc.account.color != null ? Color(acc.account.color!) : (isDark ? Theme.of(context).colorScheme.primary : AppColors.primary);
                              final balanceStr = Money.fromUnits(acc.balanceUnits).format(currency: settings.currency);

                              return DropdownMenuItem<String>(
                                value: acc.account.id,
                                child: Row(
                                  children: [
                                    Icon(acc.account.iconData, color: color, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        acc.account.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      balanceStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _fromAccountId = val;
                                if (_toAccountId == val) {
                                  _toAccountId = null;
                                }
                              });
                            },
                          ),
                        ),
                      ),

                      // Down Arrow Icon Separator
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.transfer.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, color: AppColors.transfer, size: 18),
                          ),
                        ),
                      ),

                      // To Account Dropdown
                      Text(
                        'TO ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _toAccountId,
                            isExpanded: true,
                            hint: const Text('Select Destination Account'),
                            dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
                            items: activeAccounts.map((acc) {
                              final color = acc.account.color != null ? Color(acc.account.color!) : (isDark ? Theme.of(context).colorScheme.primary : AppColors.primary);
                              final balanceStr = Money.fromUnits(acc.balanceUnits).format(currency: settings.currency);

                              return DropdownMenuItem<String>(
                                value: acc.account.id,
                                child: Row(
                                  children: [
                                    Icon(acc.account.iconData, color: color, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        acc.account.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      balanceStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _toAccountId = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Amount Input
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRANSFER AMOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _amountController,
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            settings.currencySymbol,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Theme.of(context).colorScheme.primary : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Date & Comment Card
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? Theme.of(context).colorScheme.primary : AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormatter.formatDate(_date),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'COMMENT (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _commentController,
                        hintText: 'e.g. Monthly rent transfer, savings allocation',
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Transfer Action Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveTransfer,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                  label: Text(
                    _isSaving ? 'Processing Transfer...' : 'Transfer Funds',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
