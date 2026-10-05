import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utilities/id_generator.dart';
import '../../../../core/utilities/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/currency_picker_dialog.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _openingBalanceController = TextEditingController(text: '0.00');
  AccountType _selectedAccountType = AccountType.bank;
  AppCurrency _selectedCurrency = AppCurrency.inr;
  bool _isFinishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _accountNameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name.')),
        );
        return;
      }
    }

    if (_currentPage == 3) {
      final accountName = _accountNameController.text.trim();
      if (accountName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an account name.')),
        );
        return;
      }
    }

    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim();
    final accountName = _accountNameController.text.trim();

    setState(() => _isFinishing = true);

    try {
      final settings = context.read<SettingsProvider>();
      final accProvider = context.read<AccountProvider>();

      final balanceDouble = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;
      final openingBalanceUnits = (balanceDouble * 100).round();

      final accountId = IdGenerator.generate();
      final newAccount = Account(
        id: accountId,
        name: accountName.isNotEmpty ? accountName : 'Main Account',
        accountType: _selectedAccountType,
        openingBalance: Money.fromUnits(openingBalanceUnits),
        currency: _selectedCurrency.code,
        icon: _selectedAccountType == AccountType.cash ? 'payments_outlined' : 'account_balance_outlined',
        color: _selectedAccountType == AccountType.cash ? 0xFF059669 : 0xFF2563EB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await accProvider.createAccount(newAccount);
      await accProvider.loadAccounts();

      // Configure persistent profile and settings
      settings.setProfileName(name.isNotEmpty ? name : 'User');
      settings.setCurrency(_selectedCurrency);
      settings.setPrimaryAccountId(newAccount.id);
      settings.setDefaultTransactionAccountId(newAccount.id);
      settings.setDashboardFocus(DashboardFocusMode.primaryAccount);
      settings.setOnboardingCompleted(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing setup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stepper Dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isActive = index <= _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // 5 Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomeStep(isDark),
                  _buildDisplayNameStep(isDark),
                  _buildCurrencyStep(isDark),
                  _buildPrimaryAccountStep(isDark),
                  _buildCompletionStep(isDark),
                ],
              ),
            ),

            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0 && _currentPage < 4) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isFinishing ? null : _nextPage,
                      child: _isFinishing
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentPage == 0
                                  ? 'Get Started'
                                  : (_currentPage == 4 ? 'Start using Kals' : 'Continue'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Welcome Slide
  Widget _buildWelcomeStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Welcome to Kals',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Money management,\nkept simple and private.\n\nEverything stays on\nthis device.',
            style: TextStyle(
              fontSize: 15.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 2. Display Name Slide
  Widget _buildDisplayNameStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What should we call you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'This name is used only inside\nyour Kals Money Manager.',
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              label: 'YOUR NAME',
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              hintText: 'e.g. Your name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              onSubmitted: (_) => _nextPage(),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Currency Slide
  Widget _buildCurrencyStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose your currency',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'All transactions, accounts, and reports will use this currency.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () async {
                final picked = await CurrencyPickerDialog.show(
                  context,
                  selectedCurrency: _selectedCurrency,
                );
                if (picked != null) {
                  setState(() => _selectedCurrency = picked);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Text(_selectedCurrency.flag, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedCurrency.name} (${_selectedCurrency.code} ${_selectedCurrency.symbol})',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Primary Account Slide
  Widget _buildPrimaryAccountStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create your first account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your main account. You can create additional accounts anytime.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'ACCOUNT NAME',
                  controller: _accountNameController,
                  hintText: 'e.g. Main Account',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text('ACCOUNT TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<AccountType>(
                  initialValue: _selectedAccountType,
                  decoration: const InputDecoration(isDense: true),
                  items: AccountType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.displayName));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAccountType = val);
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'OPENING BALANCE',
                  controller: _openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _selectedCurrency.symbol,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Completion Slide
  Widget _buildCompletionStep(bool isDark) {
    final name = _nameController.text.trim();
    final greeting = name.isNotEmpty ? "You're all set, $name." : "You're all set.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            greeting,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your money stays on this device.',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow(isDark, 'Display Name', name.isNotEmpty ? name : 'User'),
                const Divider(height: 18),
                _summaryRow(isDark, 'Currency', '${_selectedCurrency.name} (${_selectedCurrency.symbol})'),
                const Divider(height: 18),
                _summaryRow(isDark, 'Primary Account', _accountNameController.text.trim().isNotEmpty ? _accountNameController.text.trim() : 'Main Account'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

