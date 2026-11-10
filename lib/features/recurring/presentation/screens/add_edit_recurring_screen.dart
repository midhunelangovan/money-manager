import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/app_snack_bar.dart';
import '../../../../core/utilities/date_formatter.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/amount_input.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_select_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_grid.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../providers/recurring_provider.dart';

class AddEditRecurringScreen extends StatefulWidget {
  final RecurringTransaction? initialRecurring;

  const AddEditRecurringScreen({super.key, this.initialRecurring});

  @override
  State<AddEditRecurringScreen> createState() => _AddEditRecurringScreenState();
}

class _AddEditRecurringScreenState extends State<AddEditRecurringScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late CategoryType _type;
  late RecurringFrequency _frequency;
  late int _interval;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _remindMe = false;
  int _reminderLeadDays = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecurring;
    _descriptionController = TextEditingController(text: rec?.description ?? '');
    _amountController = TextEditingController(
      text: rec != null ? (rec.amount.units / 100).toStringAsFixed(2) : '',
    );
    _type = rec?.transactionType ?? CategoryType.expense;
    _frequency = rec?.frequency ?? RecurringFrequency.monthly;
    _interval = rec?.interval ?? 1;
    _startDate = rec?.startDate ?? DateTime.now();
    _endDate = rec?.endDate;
    _selectedAccountId = rec?.accountId;
    _selectedCategoryId = rec?.categoryId;
    _remindMe = rec?.remindMe ?? false;
    _reminderLeadDays = rec?.reminderLeadDays ?? 0;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate.add(const Duration(days: 365))),
      firstDate: isStart ? DateTime(2000) : _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showAllCategoriesSheet(List<Category> allCategories) async {
    final selected = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => CategoriesScreen(
          isPickerMode: true,
          initialType: _type,
          selectedCategoryId: _selectedCategoryId,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCategoryId = selected.id);
    }
  }

  Future<void> _save() async {
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      AppSnackBar.showError(context, 'Please enter a description for this recurring schedule');
      return;
    }

    final amountParsed = Money.tryParse(_amountController.text);
    if (amountParsed == null || amountParsed.units <= 0) {
      AppSnackBar.showError(context, 'Please enter a valid amount greater than zero');
      return;
    }

    if (_selectedAccountId == null) {
      AppSnackBar.showError(context, 'Please select an account');
      return;
    }

    if (_selectedCategoryId == null) {
      AppSnackBar.showError(context, 'Please select a category');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      DateTime nextRun = _startDate;

      if (widget.initialRecurring == null) {
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final isPastMonth = _startDate.isBefore(currentMonthStart);

        if (isPastMonth) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentMonthLabel = DateFormatter.formatMonthYear(now);
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Include payment for $currentMonthLabel?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              content: Text(
                'The start date (${DateFormatter.formatDate(_startDate)}) is in the past. Would you like to include this payment for $currentMonthLabel or start from next month?',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Start from next month',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Include this month'),
                ),
              ],
            ),
          );

          if (result == null) {
            if (mounted) setState(() => _isSaving = false);
            return;
          }

          if (result == true) {
            final maxDaysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
            final targetDay = _startDate.day.clamp(1, maxDaysInCurrentMonth);
            nextRun = DateTime(now.year, now.month, targetDay, _startDate.hour, _startDate.minute);
          } else {
            final nextMonth = now.month == 12 ? 1 : now.month + 1;
            final nextYear = now.month == 12 ? now.year + 1 : now.year;
            final maxDaysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
            final targetDay = _startDate.day.clamp(1, maxDaysInNextMonth);
            nextRun = DateTime(nextYear, nextMonth, targetDay, _startDate.hour, _startDate.minute);
          }
        }
      } else {
        nextRun = widget.initialRecurring!.nextExecutionDate;
      }

      final recurring = RecurringTransaction(
        id: widget.initialRecurring?.id ?? IdGenerator.generate(),
        transactionType: _type,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId!,
        amount: amountParsed,
        description: desc,
        frequency: _frequency,
        interval: _interval,
        startDate: _startDate,
        endDate: _endDate,
        nextExecutionDate: nextRun,
        isActive: widget.initialRecurring?.isActive ?? true,
        remindMe: _remindMe,
        reminderLeadDays: _reminderLeadDays,
        createdAt: widget.initialRecurring?.createdAt ?? now,
        updatedAt: now,
      );

      if (!mounted) return;

      if (widget.initialRecurring != null) {
        await context.read<RecurringProvider>().updateRecurring(recurring);
      } else {
        await context.read<RecurringProvider>().createRecurring(recurring);
      }

      if (mounted) {
        final isNew = widget.initialRecurring == null;
        final hasReminder = _remindMe;
        final leadDays = _reminderLeadDays;
        Navigator.of(context).pop(true);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rootContext = MainNavigationService.navigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            final messenger = ScaffoldMessenger.maybeOf(rootContext);
            if (messenger != null) {
              messenger.clearSnackBars();
              final successMsg = isNew
                  ? (hasReminder
                      ? 'Recurring payment added successfully. Reminder set for ${leadDays == 0 ? "due date" : "$leadDays days before"}.'
                      : 'Recurring payment added successfully.')
                  : (hasReminder
                      ? 'Recurring payment updated successfully. Reminder set for ${leadDays == 0 ? "due date" : "$leadDays days before"}.'
                      : 'Recurring payment updated successfully.');
              AppSnackBar.showSuccess(rootContext, successMsg);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save recurring schedule: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountProvider = context.watch<AccountProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final accounts = accountProvider.accountsWithBalances.map((a) => a.account).toList();
    final List<Category> categories = _type == CategoryType.income
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          AppHeader(
            title: widget.initialRecurring != null ? 'Edit Recurring Schedule' : 'New Recurring Schedule',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // 1. Description / Title Input with unified AppTextField
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESCRIPTION / TITLE',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _descriptionController,
                        hintText: 'e.g. Monthly Rent, SIP Investment, Netflix',
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Type Selector (Expense / Income)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TYPE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      SegmentedButton<CategoryType>(
                        segments: const [
                          ButtonSegment(
                            value: CategoryType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_downward_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: CategoryType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_upward_rounded, size: 16),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (set) {
                          setState(() {
                            _type = set.first;
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Amount Input
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: AmountInputField(
                    controller: _amountController,
                    currencySymbol: context.watch<SettingsProvider>().currencySymbol,
                    color: _type == CategoryType.income ? AppColors.income : AppColors.expense,
                    label: 'AMOUNT',
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Account Selection
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: AppSelectField<String>(
                    label: 'ACCOUNT',
                    hint: 'Select Account',
                    value: _selectedAccountId,
                    items: accounts.map((a) {
                      return AppSelectItem<String>(
                        value: a.id,
                        title: a.name,
                        icon: a.iconData,
                        iconColor: a.color != null ? Color(a.color!) : AppColors.primary,
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Category Selection (Visual Icon Grid with prominent icons)
                AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CategoryGrid(
                        categories: categories,
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: (cat) => setState(() => _selectedCategoryId = cat.id),
                        onMoreTap: () => _showAllCategoriesSheet(categories),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 6. Frequency & Start Date
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSelectField<RecurringFrequency>(
                        label: 'FREQUENCY',
                        value: _frequency,
                        searchable: false,
                        items: RecurringFrequency.values.map((f) {
                          return AppSelectItem<RecurringFrequency>(
                            value: f,
                            title: f.displayName,
                            icon: Icons.repeat_rounded,
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
                        },
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Start Date / Next Run',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          InkWell(
                            onTap: () => _pickDate(isStart: true),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    DateFormatter.formatDate(_startDate),
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 7. Payment Reminders (Remind me with lead days selection)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                size: 20,
                                color: _remindMe
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remind me',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _remindMe,
                            activeTrackColor: AppColors.primary,
                            activeThumbColor: Colors.white,
                            onChanged: (val) async {
                              if (val) {
                                final granted = await NotificationService().requestPermissions();
                                if (!granted) {
                                  if (!context.mounted) return;
                                  AppSnackBar.showError(
                                    context,
                                    'Notifications are disabled. Please enable them in settings to receive reminders.',
                                  );
                                }
                              }
                              if (mounted) {
                                setState(() => _remindMe = val);
                              }
                            },
                          ),
                        ],
                      ),
                      if (_remindMe) ...[
                        const Divider(height: 20),
                        Text(
                          'NOTIFICATION TIMING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildLeadDayChip(0, 'On due date', isDark),
                            _buildLeadDayChip(1, '1 day before', isDark),
                            _buildLeadDayChip(3, '3 days before', isDark),
                            _buildLeadDayChip(7, '7 days before', isDark),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          widget.initialRecurring != null ? 'Save Changes' : 'Create Schedule',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadDayChip(int days, String label, bool isDark) {
    final isSelected = _reminderLeadDays == days;
    return InkWell(
      onTap: () => setState(() => _reminderLeadDays = days),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}
