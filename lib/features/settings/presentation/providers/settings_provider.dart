import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/period_selector.dart';
import '../../../../core/widgets/transaction_type_tabs.dart';

enum DashboardFocusMode {
  primaryAccount('Primary Account'),
  allAccounts('All Accounts'),
  selectedAccount('Selected Account');

  final String displayName;
  const DashboardFocusMode(this.displayName);
}

class SettingsProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isOnboardingCompleted = false;
  ThemeMode _themeMode = ThemeMode.system;
  AppAccentColor _accentColor = AppAccentColor.slateBlue;
  AppCurrency _currency = AppCurrency.inr;
  bool _isAppLockEnabled = false;
  String _profileName = 'User';

  String? _primaryAccountId;
  DashboardFocusMode _dashboardFocus = DashboardFocusMode.primaryAccount;
  String? _dashboardSelectedAccountId;
  String? _defaultTransactionAccountId;
  TimePeriod _defaultPeriod = TimePeriod.week;
  LedgerTabType _defaultTransactionType = LedgerTabType.expenses;

  final AppDatabase? _appDatabase;

  SettingsProvider({AppDatabase? database}) : _appDatabase = database {
    loadSettings();
  }

  bool get isLoading => _isLoading;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  ThemeMode get themeMode => _themeMode;
  AppAccentColor get accentColor => _accentColor;
  AppCurrency get currency => _currency;
  String get currencyCode => _currency.code;
  String get currencySymbol => _currency.symbol;
  bool get isAppLockEnabled => _isAppLockEnabled;
  String get profileName => _profileName;

  String? get primaryAccountId => _primaryAccountId;
  DashboardFocusMode get dashboardFocus => _dashboardFocus;
  String? get dashboardSelectedAccountId => _dashboardSelectedAccountId;
  String? get defaultTransactionAccountId => _defaultTransactionAccountId;
  TimePeriod get defaultPeriod => _defaultPeriod;
  LedgerTabType get defaultTransactionType => _defaultTransactionType;

  AppDatabase get _db => _appDatabase ?? AppDatabase.instance;

  Future<void> loadSettings() async {
    try {
      final db = _db;

      final themeStr = await db.getSetting('theme_mode');
      if (themeStr != null) {
        if (themeStr == 'dark') _themeMode = ThemeMode.dark;
        if (themeStr == 'light') _themeMode = ThemeMode.light;
        if (themeStr == 'system') _themeMode = ThemeMode.system;
      }

      final accentStr = await db.getSetting('accent_color');
      if (accentStr != null) {
        final found = AppAccentColor.values.where((a) => a.name == accentStr).firstOrNull;
        if (found != null) _accentColor = found;
      }

      final currencyStr = await db.getSetting('currency_code');
      if (currencyStr != null) {
        final found = AppCurrency.supportedCurrencies.where((c) => c.code == currencyStr).firstOrNull;
        if (found != null) _currency = found;
      }

      final lockStr = await db.getSetting('app_lock_enabled');
      if (lockStr != null) {
        _isAppLockEnabled = lockStr == 'true';
      }

      final profileStr = await db.getSetting('profile_name');
      if (profileStr != null && profileStr.trim().isNotEmpty) {
        _profileName = profileStr.trim();
      }

      final primaryAccStr = await db.getSetting('primary_account_id');
      if (primaryAccStr != null) {
        _primaryAccountId = primaryAccStr;
      }

      final focusStr = await db.getSetting('dashboard_focus');
      if (focusStr != null) {
        final found = DashboardFocusMode.values.where((f) => f.name == focusStr).firstOrNull;
        if (found != null) _dashboardFocus = found;
      }

      final selectedAccStr = await db.getSetting('dashboard_selected_account_id');
      if (selectedAccStr != null) {
        _dashboardSelectedAccountId = selectedAccStr;
      }

      final defaultTxAccStr = await db.getSetting('default_tx_account_id');
      if (defaultTxAccStr != null) {
        _defaultTransactionAccountId = defaultTxAccStr;
      }

      final defaultPeriodStr = await db.getSetting('default_period');
      if (defaultPeriodStr != null) {
        final found = TimePeriod.values.where((p) => p.name == defaultPeriodStr).firstOrNull;
        if (found != null) _defaultPeriod = found;
      }

      final defaultTypeStr = await db.getSetting('default_tx_type');
      if (defaultTypeStr != null) {
        final found = LedgerTabType.values.where((t) => t.name == defaultTypeStr).firstOrNull;
        if (found != null) _defaultTransactionType = found;
      }

      // Check onboarding state
      final onboardStr = await db.getSetting('is_onboarding_completed');
      if (onboardStr != null) {
        _isOnboardingCompleted = onboardStr == 'true';
      } else {
        // Safe check for existing installations: if database already has transactions or custom profile, skip onboarding
        final database = await db.database;
        final txCount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
        final transferCount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM transfers')) ?? 0;
        final hasCustomProfile = profileStr != null && profileStr.trim().isNotEmpty && profileStr.trim().toLowerCase() != 'user';

        if (txCount > 0 || transferCount > 0 || hasCustomProfile) {
          _isOnboardingCompleted = true;
          await db.setSetting('is_onboarding_completed', 'true');
        } else {
          _isOnboardingCompleted = false;
        }
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setOnboardingCompleted(bool completed) {
    _isOnboardingCompleted = completed;
    notifyListeners();
    _db.setSetting('is_onboarding_completed', completed ? 'true' : 'false');
  }

  void setProfileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && _profileName != trimmed) {
      _profileName = trimmed;
      notifyListeners();
      _db.setSetting('profile_name', trimmed);
    }
  }

  void setPrimaryAccountId(String? accountId) {
    _primaryAccountId = accountId;
    notifyListeners();
    if (accountId != null) {
      _db.setSetting('primary_account_id', accountId);
    }
  }

  void setDashboardFocus(DashboardFocusMode focus) {
    _dashboardFocus = focus;
    notifyListeners();
    _db.setSetting('dashboard_focus', focus.name);
  }

  void setDashboardSelectedAccountId(String? accountId) {
    _dashboardSelectedAccountId = accountId;
    notifyListeners();
    if (accountId != null) {
      _db.setSetting('dashboard_selected_account_id', accountId);
    }
  }

  void setDefaultTransactionAccountId(String? accountId) {
    _defaultTransactionAccountId = accountId;
    notifyListeners();
    if (accountId != null) {
      _db.setSetting('default_tx_account_id', accountId);
    }
  }

  void setDefaultPeriod(TimePeriod period) {
    _defaultPeriod = period;
    notifyListeners();
    _db.setSetting('default_period', period.name);
  }

  void setDefaultTransactionType(LedgerTabType type) {
    _defaultTransactionType = type;
    notifyListeners();
    _db.setSetting('default_tx_type', type.name);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      _db.setSetting('theme_mode', mode.name);
    }
  }

  void setAccentColor(AppAccentColor accent) {
    if (_accentColor != accent) {
      _accentColor = accent;
      notifyListeners();
      _db.setSetting('accent_color', accent.name);
    }
  }

  void setCurrency(AppCurrency newCurrency) {
    if (_currency != newCurrency) {
      _currency = newCurrency;
      notifyListeners();
      _db.setSetting('currency_code', newCurrency.code);
    }
  }

  void setAppLockEnabled(bool enabled) {
    if (_isAppLockEnabled != enabled) {
      _isAppLockEnabled = enabled;
      notifyListeners();
      _db.setSetting('app_lock_enabled', enabled ? 'true' : 'false');
    }
  }
}

