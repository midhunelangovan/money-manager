import 'package:flutter/material.dart';
import '../constants/app_currency.dart';
import '../theme/app_colors.dart';

class CurrencyPickerDialog extends StatefulWidget {
  final AppCurrency selectedCurrency;

  const CurrencyPickerDialog({
    super.key,
    required this.selectedCurrency,
  });

  static Future<AppCurrency?> show(
    BuildContext context, {
    required AppCurrency selectedCurrency,
  }) {
    return showModalBottomSheet<AppCurrency>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CurrencyPickerDialog(selectedCurrency: selectedCurrency),
    );
  }

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  late TextEditingController _searchController;
  List<AppCurrency> _filteredCurrencies = AppCurrency.supportedCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredCurrencies = AppCurrency.supportedCurrencies;
      } else {
        _filteredCurrencies = AppCurrency.supportedCurrencies.where((c) {
          return c.name.toLowerCase().contains(clean) ||
              c.code.toLowerCase().contains(clean) ||
              c.symbol.toLowerCase().contains(clean);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Currency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies by name or code...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _onSearch,
              ),

              const SizedBox(height: 14),

              // Currency List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _filteredCurrencies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final curr = _filteredCurrencies[index];
                    final isSelected = curr.code == widget.selectedCurrency.code;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                            : (isDark ? AppColors.darkSurfaceCard : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pop(context, curr),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Text(
                                curr.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${curr.name} (${curr.code} ${curr.symbol})',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
