import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transfers/presentation/providers/transfer_provider.dart';
import '../../data/services/excel_import_service.dart';
import '../providers/excel_import_provider.dart';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcelImportProvider>().reset();
    });
  }

  void _onImportFinished(BuildContext context) {
    context.read<AccountProvider>().loadAccounts();
    context.read<CategoryProvider>().loadCategories();
    context.read<TransactionProvider>().loadLedger();
    context.read<TransferProvider>().loadTransfers();
    Navigator.of(context).pop();
  }

  void _showAccountPickerSheet(
    BuildContext context,
    ExcelImportProvider provider,
    String legacyName,
    AccountMappingEntry currentEntry,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final existingAccounts = provider.analysis?.existingAccounts ?? [];
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = existingAccounts.where((a) {
              if (searchQuery.isEmpty) return true;
              return a.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Map Legacy Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Legacy: "$legacyName"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Select Action Header
                      Text(
                        'Select Action',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Option 1: Create New
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          provider.updateAccountMapping(
                            legacyName: legacyName,
                            targetAccountId: currentEntry.targetAccountId ?? IdGenerator.generate(),
                            targetAccountName: legacyName,
                            status: MappingStatus.createNew,
                          );
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: currentEntry.status == MappingStatus.createNew
                                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                                : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightBackground),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentEntry.status == MappingStatus.createNew
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentEntry.status == MappingStatus.createNew
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: currentEntry.status == MappingStatus.createNew
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+ Create new "$legacyName"',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: currentEntry.status == MappingStatus.createNew
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    Text(
                                      'Will be created in Kals upon final import confirmation',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Option 2 Header & Ignore Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OR MAP TO EXISTING ACCOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                            icon: Icon(
                              Icons.block_rounded,
                              size: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            label: Text(
                              'Ignore',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            onPressed: () {
                              provider.updateAccountMapping(
                                legacyName: legacyName,
                                targetAccountId: null,
                                targetAccountName: null,
                                status: MappingStatus.ignored,
                              );
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Search Input
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Kals accounts...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        onChanged: (val) {
                          setSheetState(() => searchQuery = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      // Accounts List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching accounts found.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final acc = filtered[index];
                                  final isSelected = acc.id == currentEntry.targetAccountId;
                                  final isArchived = acc.isArchived;

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: (acc.color != null ? Color(acc.color!) : AppColors.primary).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        acc.iconData,
                                        size: 18,
                                        color: acc.color != null ? Color(acc.color!) : AppColors.primary,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            acc.name,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isArchived) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Deleted',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      acc.accountType.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                        : (isArchived
                                            ? TextButton(
                                                onPressed: () {
                                                  provider.restoreAndMapAccount(
                                                    legacyName: legacyName,
                                                    accountId: acc.id,
                                                    accountName: acc.name,
                                                  );
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                              )
                                            : null),
                                    onTap: () {
                                      if (isArchived) {
                                        provider.restoreAndMapAccount(
                                          legacyName: legacyName,
                                          accountId: acc.id,
                                          accountName: acc.name,
                                        );
                                      } else {
                                        provider.updateAccountMapping(
                                          legacyName: legacyName,
                                          targetAccountId: acc.id,
                                          targetAccountName: acc.name,
                                          status: MappingStatus.exactMatch,
                                        );
                                      }
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCategoryPickerSheet(
    BuildContext context,
    ExcelImportProvider provider,
    String legacyName,
    CategoryMappingEntry currentEntry,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expectedType = currentEntry.categoryType;
    final allCategories = provider.analysis?.existingCategories ?? [];
    final typeCategories = allCategories.where((c) => c.type == expectedType).toList();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = typeCategories.where((c) {
              if (searchQuery.isEmpty) return true;
              return c.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Map Legacy ${expectedType == CategoryType.income ? "Income" : "Expense"} Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Legacy: "$legacyName"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Select Action Header
                      Text(
                        'Select Action',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Option 1: Create New Category
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          provider.updateCategoryMapping(
                            legacyName: legacyName,
                            targetCategoryId: currentEntry.targetCategoryId ?? IdGenerator.generate(),
                            targetCategoryName: legacyName,
                            status: MappingStatus.createNew,
                          );
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: currentEntry.status == MappingStatus.createNew
                                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                                : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightBackground),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentEntry.status == MappingStatus.createNew
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentEntry.status == MappingStatus.createNew
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: currentEntry.status == MappingStatus.createNew
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+ Create new "$legacyName"',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: currentEntry.status == MappingStatus.createNew
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    Text(
                                      'Will create a new ${expectedType == CategoryType.income ? "Income" : "Expense"} category upon final import confirmation',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Option 2 Header & Ignore Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OR MAP TO EXISTING ${expectedType == CategoryType.income ? "INCOME" : "EXPENSE"} CATEGORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                            icon: Icon(
                              Icons.block_rounded,
                              size: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            label: Text(
                              'Ignore',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            onPressed: () {
                              provider.updateCategoryMapping(
                                legacyName: legacyName,
                                targetCategoryId: null,
                                targetCategoryName: null,
                                status: MappingStatus.ignored,
                              );
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Search Input
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Kals ${expectedType == CategoryType.income ? "Income" : "Expense"} categories...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        onChanged: (val) {
                          setSheetState(() => searchQuery = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      // Category List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching ${expectedType == CategoryType.income ? "Income" : "Expense"} categories found.\nTap "+ Create Category" above to add one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final cat = filtered[index];
                                  final isSelected = cat.id == currentEntry.targetCategoryId;

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: (cat.color != null ? Color(cat.color!) : AppColors.primary).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        cat.iconData,
                                        size: 18,
                                        color: cat.color != null ? Color(cat.color!) : AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    subtitle: Text(
                                      cat.type == CategoryType.income ? 'Income' : 'Expense',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                        : null,
                                    onTap: () {
                                      provider.updateCategoryMapping(
                                        legacyName: legacyName,
                                        targetCategoryId: cat.id,
                                        targetCategoryName: cat.name,
                                        status: MappingStatus.exactMatch,
                                      );
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExcelImportProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: _getHeaderTitle(provider.currentStep),
              showBackButton: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => _handleBack(context, provider),
                tooltip: 'Back',
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Processing legacy financial records...',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildStepContent(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderTitle(ImportWizardStep step) {
    switch (step) {
      case ImportWizardStep.selectFileAndSheet:
        return 'Import from Excel';
      case ImportWizardStep.accountMapping:
        return 'Account Mapping';
      case ImportWizardStep.categoryMapping:
        return 'Category Mapping';
      case ImportWizardStep.previewAndValidate:
        return 'Import Preview';
      case ImportWizardStep.importResult:
        return 'Import Result';
    }
  }

  void _handleBack(BuildContext context, ExcelImportProvider provider) {
    switch (provider.currentStep) {
      case ImportWizardStep.selectFileAndSheet:
        Navigator.of(context).pop();
        break;
      case ImportWizardStep.accountMapping:
        provider.setStep(ImportWizardStep.selectFileAndSheet);
        break;
      case ImportWizardStep.categoryMapping:
        provider.setStep(ImportWizardStep.accountMapping);
        break;
      case ImportWizardStep.previewAndValidate:
        if (provider.categoryMappings.isEmpty) {
          provider.setStep(ImportWizardStep.accountMapping);
        } else {
          provider.setStep(ImportWizardStep.categoryMapping);
        }
        break;
      case ImportWizardStep.importResult:
        _onImportFinished(context);
        break;
    }
  }

  Widget _buildStepContent(BuildContext context, ExcelImportProvider provider) {
    if (provider.errorMessage != null) {
      return _buildErrorView(context, provider);
    }

    switch (provider.currentStep) {
      case ImportWizardStep.selectFileAndSheet:
        return _buildFileAndSheetSelector(context, provider);
      case ImportWizardStep.accountMapping:
        return _buildAccountMappingStep(context, provider);
      case ImportWizardStep.categoryMapping:
        return _buildCategoryMappingStep(context, provider);
      case ImportWizardStep.previewAndValidate:
        return _buildPreviewAndValidation(context, provider);
      case ImportWizardStep.importResult:
        return _buildImportResult(context, provider);
    }
  }

  Widget _buildErrorView(BuildContext context, ExcelImportProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 48),
            const SizedBox(height: 16),
            Text(
              'Import Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => provider.reset(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAndSheetSelector(BuildContext context, ExcelImportProvider provider) {
    final workbook = provider.workbookInfo;
    final selectedSheets = provider.selectedSheetNames;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legacy Excel Importer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select your legacy spreadsheet (.xlsx). You can select multiple sheets (Expenses, Income, Transfers) and map legacy accounts/categories to your existing Kals structure in a single unified step.',
                      style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '1. SELECT EXCEL FILE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (workbook == null) ...[
                const Text('No file selected', style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.file_open_rounded, color: AppColors.primary),
                    label: const Text(
                      'Select Excel File (.xlsx)',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => provider.pickExcelFile(),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.table_view_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workbook.fileName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${workbook.sheetNames.length} sheet(s) detected',
                            style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.lightTextSecondary),
                      tooltip: 'Change File',
                      onPressed: () => provider.pickExcelFile(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (workbook != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. SELECT SHEETS TO IMPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () => provider.selectAllSheets(),
                child: const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...workbook.sheetNames.map((sheetName) {
            final isSelected = selectedSheets.contains(sheetName);
            final sheetType = ExcelSheetType.fromName(sheetName);

            IconData iconData = Icons.receipt_long_rounded;
            Color iconColor = AppColors.primary;

            if (sheetType == ExcelSheetType.expenses) {
              iconData = Icons.arrow_upward_rounded;
              iconColor = AppColors.expense;
            } else if (sheetType == ExcelSheetType.income) {
              iconData = Icons.arrow_downward_rounded;
              iconColor = AppColors.income;
            } else if (sheetType == ExcelSheetType.transfers) {
              iconData = Icons.swap_horiz_rounded;
              iconColor = AppColors.transfer;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onTap: () => provider.toggleSheetSelection(sheetName),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheetName,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sheetType.displayName,
                            style: TextStyle(fontSize: 12, color: iconColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (_) => provider.toggleSheetSelection(sheetName),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: selectedSheets.isEmpty ? null : () => provider.analyzeSelectedSheets(),
            child: Text(
              'Analyze Data & Continue (${selectedSheets.length} selected)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAccountMappingStep(BuildContext context, ExcelImportProvider provider) {
    final accountMappings = provider.accountMappings;
    final entries = accountMappings.values.toList();

    final unmappedCount = entries.where((a) => a.status == MappingStatus.unmapped).length;
    final matchedCount = entries.where((a) => a.status == MappingStatus.exactMatch).length;
    final suggestedCount = entries.where((a) => a.status == MappingStatus.suggested).length;
    final canProceed = unmappedCount == 0;

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.lightSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'ACCOUNT MAPPING',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} detected',
                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildBadgeSummary('Matched', '$matchedCount', AppColors.income),
                  const SizedBox(width: 8),
                  _buildBadgeSummary('Suggested', '$suggestedCount', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildBadgeSummary('Unmapped', '$unmappedCount', unmappedCount > 0 ? AppColors.expense : AppColors.lightTextSecondary),
                ],
              ),
              if (unmappedCount > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Map all legacy accounts to existing Kals accounts, or create new ones before proceeding.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // Accounts list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildMappingCard(
                title: entry.legacyName,
                subtitle: '${entry.transactionCount} transaction(s)',
                targetName: entry.targetAccountName,
                status: entry.status,
                isTargetArchived: entry.isTargetArchived,
                onTap: () => _showAccountPickerSheet(context, provider, entry.legacyName, entry),
                onQuickConfirm: entry.status == MappingStatus.suggested
                    ? () {
                        provider.updateAccountMapping(
                          legacyName: entry.legacyName,
                          targetAccountId: entry.targetAccountId,
                          targetAccountName: entry.targetAccountName,
                          status: MappingStatus.exactMatch,
                        );
                      }
                    : null,
              );
            },
          ),
        ),

        // Bottom continue button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
            border: Border(top: BorderSide(color: AppColors.lightBorder)),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? AppColors.primary : AppColors.lightBorder,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: canProceed
                ? () {
                    if (provider.categoryMappings.isEmpty) {
                      provider.generatePreview();
                    } else {
                      provider.setStep(ImportWizardStep.categoryMapping);
                    }
                  }
                : null,
            child: Text(
              canProceed
                  ? (provider.categoryMappings.isEmpty ? 'Continue to Preview' : 'Continue to Category Mapping')
                  : 'Resolve $unmappedCount Unmapped Account(s)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMappingStep(BuildContext context, ExcelImportProvider provider) {
    final categoryMappings = provider.categoryMappings;
    final entries = categoryMappings.values.toList();

    final unmappedCount = entries.where((c) => c.status == MappingStatus.unmapped).length;
    final matchedCount = entries.where((c) => c.status == MappingStatus.exactMatch).length;
    final suggestedCount = entries.where((c) => c.status == MappingStatus.suggested).length;
    final canProceed = unmappedCount == 0;

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.lightSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.category_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'CATEGORY MAPPING',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} detected',
                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildBadgeSummary('Matched', '$matchedCount', AppColors.income),
                  const SizedBox(width: 8),
                  _buildBadgeSummary('Suggested', '$suggestedCount', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildBadgeSummary('Unmapped', '$unmappedCount', unmappedCount > 0 ? AppColors.expense : AppColors.lightTextSecondary),
                ],
              ),
              if (unmappedCount > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Map legacy categories to existing Kals categories, or create new ones before proceeding.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // Categories list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildMappingCard(
                title: entry.legacyName,
                subtitle: '${entry.categoryType == CategoryType.income ? "Income" : "Expense"} • ${entry.transactionCount} transaction(s)',
                targetName: entry.targetCategoryName,
                status: entry.status,
                onTap: () => _showCategoryPickerSheet(context, provider, entry.legacyName, entry),
                onQuickConfirm: entry.status == MappingStatus.suggested
                    ? () {
                        provider.updateCategoryMapping(
                          legacyName: entry.legacyName,
                          targetCategoryId: entry.targetCategoryId,
                          targetCategoryName: entry.targetCategoryName,
                          status: MappingStatus.exactMatch,
                        );
                      }
                    : null,
              );
            },
          ),
        ),

        // Bottom continue button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
            border: Border(top: BorderSide(color: AppColors.lightBorder)),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? AppColors.primary : AppColors.lightBorder,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: canProceed ? () => provider.generatePreview() : null,
            child: Text(
              canProceed ? 'Continue to Preview' : 'Resolve $unmappedCount Unmapped Category(s)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingCard({
    required String title,
    required String subtitle,
    required String? targetName,
    required MappingStatus status,
    bool isTargetArchived = false,
    required VoidCallback onTap,
    VoidCallback? onQuickConfirm,
  }) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case MappingStatus.exactMatch:
        statusColor = AppColors.income;
        statusLabel = 'Matched';
        statusIcon = Icons.check_circle_rounded;
        break;
      case MappingStatus.suggested:
        statusColor = const Color(0xFFD97706);
        statusLabel = isTargetArchived ? 'Deleted Account' : 'Suggested';
        statusIcon = Icons.lightbulb_outline_rounded;
        break;
      case MappingStatus.createNew:
        statusColor = AppColors.primary;
        statusLabel = '+ Create';
        statusIcon = Icons.add_circle_outline_rounded;
        break;
      case MappingStatus.unmapped:
        statusColor = AppColors.expense;
        statusLabel = 'Unmapped';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case MappingStatus.ignored:
        statusColor = AppColors.lightTextSecondary;
        statusLabel = 'Ignored';
        statusIcon = Icons.block_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        status == MappingStatus.ignored
                            ? 'Ignored (Will skip)'
                            : (status == MappingStatus.createNew
                                ? '+ Create "$title"'
                                : (targetName ?? 'Tap to select')),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (targetName != null || status == MappingStatus.createNew) ? FontWeight.w600 : FontWeight.w400,
                          color: status == MappingStatus.createNew
                              ? AppColors.primary
                              : (targetName != null ? AppColors.lightTextPrimary : AppColors.expense),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down_rounded, size: 24, color: AppColors.lightTextSecondary),
            if (status == MappingStatus.suggested && onQuickConfirm != null) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD97706)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onQuickConfirm,
                child: const Text('Confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
              ),
            ] else ...[
              const Icon(Icons.chevron_right_rounded, color: AppColors.lightTextSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewAndValidation(BuildContext context, ExcelImportProvider provider) {
    final preview = provider.preview;
    if (preview == null) return const Center(child: Text('No preview data available.'));

    final duplicateCount = preview.duplicateCount;
    final validCount = preview.validCount;
    final invalidCount = preview.invalidCount;
    final sourceCoverage = preview.sourceMonthlyCoverage;

    final dateFormat = DateFormat('dd MMM yyyy');
    String? dateRangeText;
    if (preview.minDate != null && preview.maxDate != null) {
      dateRangeText = '${dateFormat.format(preview.minDate!)} – ${dateFormat.format(preview.maxDate!)}';
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(child: _buildStatBox('Source Rows', '${preview.totalRows}', AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox('Valid to Import', '$validCount', AppColors.income)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox('Duplicates', '$duplicateCount', duplicateCount > 0 ? const Color(0xFFD97706) : AppColors.lightTextSecondary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox('Invalid', '$invalidCount', invalidCount > 0 ? AppColors.expense : AppColors.lightTextSecondary)),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range Header Card
              if (dateRangeText != null) ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DETECTED DATE RANGE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateRangeText,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${sourceCoverage.length} Month(s)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Month Coverage Card
              if (sourceCoverage.isNotEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'MONTH COVERAGE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary, letterSpacing: 0.5),
                          ),
                          const Spacer(),
                          Text(
                            '${preview.totalRows} records across ${sourceCoverage.length} months',
                            style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sourceCoverage.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Sheet breakdown
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SHEET BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBreakdownItem('Expenses', '${preview.expensesCount}', AppColors.expense),
                        _buildBreakdownItem('Income', '${preview.incomeCount}', AppColors.income),
                        _buildBreakdownItem('Transfers', '${preview.transfersCount}', AppColors.transfer),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Invalid rows warning / list
              if (invalidCount > 0) ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.expense),
                          const SizedBox(width: 8),
                          Text(
                            'INVALID ROWS ($invalidCount)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.expense, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These rows cannot be imported and will be skipped:',
                        style: TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 8),
                      ...preview.invalidRows.take(10).map((inv) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${inv.sheetName} Row ${inv.rowNumber}: ',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                              ),
                              Expanded(
                                child: Text(
                                  inv.errorReason,
                                  style: const TextStyle(fontSize: 12, color: AppColors.expense),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (invalidCount > 10) ...[
                        const SizedBox(height: 4),
                        Text(
                          'And ${invalidCount - 10} more invalid row(s)...',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Column Mapping Summary Card
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.view_column_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'COLUMN MAPPING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildColumnMappingRow('Date', 'Transaction Date ✓'),
                    _buildColumnMappingRow('Amount', 'Amount ✓'),
                    _buildColumnMappingRow('Account', 'Kals Account ✓'),
                    if (preview.sheetType != ExcelSheetType.transfers)
                      _buildColumnMappingRow('Category', 'Kals Category ✓'),
                    _buildColumnMappingRow('Comment', 'Transaction Comment ✓'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Duplicate settings toggle
              if (duplicateCount > 0) ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.content_copy_rounded, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Skip $duplicateCount Duplicate(s)', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            Text(
                              provider.skipDuplicates
                                  ? 'Existing matching transactions will not be re-imported'
                                  : 'Duplicates will be imported alongside existing records',
                              style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: provider.skipDuplicates,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => provider.setSkipDuplicates(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Sample preview rows
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SAMPLE IMPORT TRANSACTIONS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary, letterSpacing: 0.5),
                  ),
                  Text(
                    'Showing ${preview.previewItems.length} of $validCount',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...preview.previewItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.sheetType == ExcelSheetType.transfers
                                ? AppColors.transfer.withValues(alpha: 0.12)
                                : (item.sheetType == ExcelSheetType.income
                                    ? AppColors.income.withValues(alpha: 0.12)
                                    : AppColors.expense.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.sheetType == ExcelSheetType.transfers
                                ? Icons.swap_horiz_rounded
                                : (item.sheetType == ExcelSheetType.income
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded),
                            size: 18,
                            color: item.sheetType == ExcelSheetType.transfers
                                ? AppColors.transfer
                                : (item.sheetType == ExcelSheetType.income
                                    ? AppColors.income
                                    : AppColors.expense),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.sheetType == ExcelSheetType.transfers
                                    ? '${item.mappedOutgoingAccountName} → ${item.mappedIncomingAccountName}'
                                    : '${item.mappedCategoryName ?? "Category"} • ${item.mappedAccountName ?? "Account"}',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy').format(item.date),
                                style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                              ),
                              if (item.comment != null && item.comment!.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.comment_outlined, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.comment!.trim(),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Neutral Amount display
                        Text(
                          item.amount.format(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Bottom Action buttons: Backup & Import + Import Now
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
            border: Border(top: BorderSide(color: AppColors.lightBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shield_outlined, size: 20),
                label: Text(
                  'Backup & Import ($validCount Transactions)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: () => provider.executeImport(createBackupFirst: true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => provider.executeImport(createBackupFirst: false),
                child: const Text(
                  'Import Without Backup',
                  style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportResult(BuildContext context, ExcelImportProvider provider) {
    final result = provider.lastResult;
    if (result == null) return const Center(child: Text('No import result available.'));

    final isReconciled = result.isReconciled;
    final sourceCoverage = result.sourceMonthlyCoverage;
    final importedCoverage = result.importedMonthlyCoverage;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (result.isSuccess ? AppColors.income : AppColors.expense).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: result.isSuccess ? AppColors.income : AppColors.expense,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          result.isSuccess ? 'Import Completed Successfully' : 'Import Incomplete / Failed',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          result.isSuccess
              ? 'All selected records have been imported and reconciled safely into Kals Money Manager.'
              : (result.errorMessage ?? 'Some records could not be imported.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Reconciliation Status Card
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isReconciled ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    size: 20,
                    color: isReconciled ? AppColors.income : AppColors.expense,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReconciled ? 'RECONCILIATION VERIFIED' : 'RECONCILIATION DISCREPANCY',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isReconciled ? AppColors.income : AppColors.expense,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isReconciled ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isReconciled ? 'PASS' : 'FAIL',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isReconciled ? AppColors.income : AppColors.expense),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Source (${result.totalSourceRows}) = Imported (${result.importedCount}) + Duplicates (${result.skippedDuplicates}) + Invalid (${result.invalidRowsCount}) + Failed (${result.failedCount})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Monthly Reconciliation Breakdown
        if (sourceCoverage.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'MONTHLY RECONCILIATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...sourceCoverage.entries.map((entry) {
                  final mKey = entry.key;
                  final srcCount = entry.value;
                  final impCount = importedCoverage[mKey] ?? 0;
                  final isMonthPass = (impCount == srcCount) || (result.skippedDuplicates > 0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mKey,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
                        ),
                        Row(
                          children: [
                            Text(
                              '$impCount / $srcCount',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isMonthPass ? AppColors.lightTextPrimary : AppColors.expense,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isMonthPass ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 16,
                              color: isMonthPass ? AppColors.income : AppColors.expense,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Detailed Stats Breakdown Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildResultRow('Source Rows Scanned', '${result.totalSourceRows}', AppColors.lightTextPrimary),
              const Divider(height: 16),
              _buildResultRow('Transactions Imported', '${result.importedCount}', AppColors.income),
              const Divider(height: 16),
              _buildResultRow('Expenses Imported', '${result.expensesImported}', AppColors.lightTextPrimary),
              const Divider(height: 16),
              _buildResultRow('Income Imported', '${result.incomeImported}', AppColors.lightTextPrimary),
              const Divider(height: 16),
              _buildResultRow('Transfers Imported', '${result.transfersImported}', AppColors.lightTextPrimary),
              const Divider(height: 16),
              _buildResultRow('Skipped as Duplicates', '${result.skippedDuplicates}', const Color(0xFFD97706)),
              const Divider(height: 16),
              _buildResultRow('Invalid Rows Skipped', '${result.invalidRowsCount}', result.invalidRowsCount > 0 ? AppColors.expense : AppColors.lightTextSecondary),
              const Divider(height: 16),
              _buildResultRow('Accounts Mapped', '${result.accountsMappedCount}', AppColors.primary),
              const Divider(height: 16),
              _buildResultRow('Categories Mapped', '${result.categoriesMappedCount}', AppColors.primary),
            ],
          ),
        ),

        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _onImportFinished(context),
          child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBadgeSummary(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildColumnMappingRow(String legacyCol, String kalsField) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(legacyCol, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.lightTextSecondary),
              const SizedBox(width: 6),
              Text(
                kalsField,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
