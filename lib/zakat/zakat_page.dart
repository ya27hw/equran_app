import 'dart:math' as math;

import 'package:equran/backend/settings_db.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/zakat/zakat_db.dart';
import 'package:equran/zakat/metal_price_service.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

/// Rich Zakat asset category definition for the modern calculator.
enum ZakatCategory {
  cash('Cash & Receivables', Icons.account_balance_wallet_outlined, 0.025),
  gold('Gold', Icons.workspace_premium_outlined, 0.025),
  silver('Silver', Icons.diamond_outlined, 0.025),
  investments('Investments & Securities', Icons.show_chart_outlined, 0.025),
  business('Business Inventory', Icons.inventory_2_outlined, 0.025),
  livestock(
    'Livestock',
    Icons.pets_outlined,
    0.025,
  ), // rates vary; engine handles
  agriculture(
    'Agricultural Produce',
    Icons.agriculture_outlined,
    0.05,
  ), // simplified
  other('Other Assets', Icons.category_outlined, 0.025);

  const ZakatCategory(this.label, this.icon, this.defaultRate);

  final String label;
  final IconData icon;
  final double defaultRate;

  String getLocalizedLabel(AppLocalizations localizations) {
    switch (this) {
      case ZakatCategory.cash:
        return localizations.zakatCategoryCash;
      case ZakatCategory.gold:
        return localizations.zakatCategoryGold;
      case ZakatCategory.silver:
        return localizations.zakatCategorySilver;
      case ZakatCategory.investments:
        return localizations.zakatCategoryInvestments;
      case ZakatCategory.business:
        return localizations.zakatCategoryBusiness;
      case ZakatCategory.livestock:
        return localizations.zakatCategoryLivestock;
      case ZakatCategory.agriculture:
        return localizations.zakatCategoryAgriculture;
      case ZakatCategory.other:
        return localizations.zakatCategoryOther;
    }
  }
}

/// Lightweight line item for rich calculations and persistence.
class ZakatLineItem {
  const ZakatLineItem({
    required this.category,
    required this.amount,
    this.rate,
    this.note,
    this.meta,
  });

  final ZakatCategory category;
  final double amount; // in base currency
  final double? rate; // override if non-standard
  final String? note;
  final Map<String, dynamic>? meta; // e.g. livestock head counts, unit info

  double get effectiveRate => rate ?? category.defaultRate;

  double get zakatPortion => amount * effectiveRate;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cat': category.name,
    'amt': amount,
    if (rate != null) 'rate': rate,
    if (note != null) 'note': note,
    if (meta != null) 'meta': meta,
  };

  factory ZakatLineItem.fromJson(Map<String, dynamic> json) {
    final catName = json['cat'] as String?;
    final category = ZakatCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => ZakatCategory.other,
    );
    return ZakatLineItem(
      category: category,
      amount: (json['amt'] as num?)?.toDouble() ?? 0.0,
      rate: (json['rate'] as num?)?.toDouble(),
      note: json['note'] as String?,
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'])
          : null,
    );
  }
}

/// Immutable result of a Zakat computation.
class _ZakatComputation {
  const _ZakatComputation({
    required this.items,
    required this.grossWealth,
    required this.liabilities,
    required this.netWealth,
    required this.nisabThreshold,
    required this.isEligible,
    required this.zakatDue,
    required this.goldPrice,
    required this.silverPrice,
  });

  final List<ZakatLineItem> items;
  final double grossWealth;
  final double liabilities;
  final double netWealth;
  final double nisabThreshold;
  final bool isEligible;
  final double zakatDue;
  final double goldPrice;
  final double silverPrice;

  double get totalZakatFromItems =>
      items.fold(0.0, (sum, i) => sum + i.zakatPortion);
}

class ZakatCalculatorPage extends StatefulWidget {
  const ZakatCalculatorPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<ZakatCalculatorPage> createState() => _ZakatCalculatorPageState();
}

class _ZakatCalculatorPageState extends State<ZakatCalculatorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Form Controllers
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _investmentsController = TextEditingController();
  final TextEditingController _goldController = TextEditingController();
  final TextEditingController _silverController = TextEditingController();
  final TextEditingController _liabilitiesController = TextEditingController();

  // Price States
  double _goldPrice = 75.80; // default/fallback gold price per gram in USD
  double _silverPrice = 0.95; // default/fallback silver price per gram in USD
  String _ratesCurrency = 'USD';
  late final MetalsLiveRateProvider _metalRateProvider;
  bool _isLoadingPrice = false;
  String _priceStatus = '';

  // Calculation Selection States
  String _nisabType = 'silver'; // 'silver' or 'gold'
  String _goldUnit = 'grams'; // 'grams' or 'bhori' (1 bhori/tola = 11.664g)
  String _silverUnit = 'grams';

  // Constants (legacy + modern)
  static const double goldNisabGrams = 87.48;
  static const double silverNisabGrams = 612.36;
  static const double bhoriToGram = 11.664;

  // ==================== NEW RICH CALCULATOR STATE ====================
  // Modern category-based amounts (primary source of truth going forward)
  final Map<ZakatCategory, double> _categoryAmounts = <ZakatCategory, double>{
    for (final c in ZakatCategory.values) c: 0.0,
  };

  // Livestock specific (more powerful than flat amount)
  int _livestockSheep = 0;
  int _livestockCows = 0;
  int _livestockCamels = 0;

  // Manual price overrides (power user feature)
  double? _goldPriceOverride;
  double? _silverPriceOverride;

  // Base currency for all calculations and prices (persisted)
  String _baseCurrency = 'USD';

  AppLocalizations get localizations => AppLocalizations.of(context)!;

  // ==================== END NEW STATE ====================

  @override
  void initState() {
    super.initState();
    _metalRateProvider = MetalsLiveRateProvider();
    _baseCurrency =
        SettingsDB().get('zakat_currency', defaultValue: 'USD') as String;
    _restoreCachedMetalRates();
    _tabController = TabController(length: 2, vsync: this);
    // Localize default status and fetch live prices on start after build/initState is done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _priceStatus =
              AppLocalizations.of(context)?.ratesSyncOffline ??
              'Market offline. Using standard cached values.';
        });
        _fetchLiveMetalPrices();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _investmentsController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _liabilitiesController.dispose();
    _metalRateProvider.close();
    super.dispose();
  }

  void _restoreCachedMetalRates() {
    final MetalRateSnapshot? cached = MetalRateSnapshot.fromMap(
      SettingsDB().get('zakat_metal_rates'),
    );
    if (cached == null || cached.currency != _baseCurrency) return;
    _goldPrice = cached.goldPricePerGram;
    _silverPrice = cached.silverPricePerGram;
    _ratesCurrency = cached.currency;
  }

  Future<void> _fetchLiveMetalPrices() async {
    setState(() {
      _isLoadingPrice = true;
      if (mounted) {
        _priceStatus =
            AppLocalizations.of(context)?.fetchingLiveRates ??
            'Fetching live market rates...';
      } else {
        _priceStatus = 'Fetching live market rates...';
      }
    });

    try {
      final MetalRateSnapshot snapshot = await _metalRateProvider.fetch(
        currency: _baseCurrency,
      );
      await SettingsDB().put('zakat_metal_rates', snapshot.toMap());
      if (!mounted) return;
      setState(() {
        _goldPrice = snapshot.goldPricePerGram;
        _silverPrice = snapshot.silverPricePerGram;
        _ratesCurrency = snapshot.currency;
        _isLoadingPrice = false;
        _priceStatus = _rateStatus(snapshot);
      });
      return;
    } catch (_) {
      final MetalRateSnapshot? cached = MetalRateSnapshot.fromMap(
        SettingsDB().get('zakat_metal_rates'),
      );
      if (cached != null && cached.currency == _baseCurrency && mounted) {
        final MetalRateSnapshot stale = cached.copyWith(isStale: true);
        setState(() {
          _goldPrice = stale.goldPricePerGram;
          _silverPrice = stale.silverPricePerGram;
          _ratesCurrency = stale.currency;
          _isLoadingPrice = false;
          _priceStatus = _rateStatus(stale);
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingPrice = false;
      _ratesCurrency = '';
      _goldPrice = 0;
      _silverPrice = 0;
      _priceStatus =
          '${AppLocalizations.of(context)?.ratesSyncOffline ?? 'Market offline. Enter independent rates manually.'} ($_baseCurrency)';
    });
  }

  String _rateStatus(MetalRateSnapshot snapshot) {
    final String freshness = snapshot.isStale ? 'stale' : 'live';
    return '${snapshot.source} • $freshness • ${snapshot.fetchedAt.toLocal().toIso8601String()}';
  }

  // ==================== RICH ZAKAT ENGINE ====================

  double get _effectiveGoldPrice =>
      _goldPriceOverride ?? (_ratesCurrency == _baseCurrency ? _goldPrice : 0);
  double get _effectiveSilverPrice =>
      _silverPriceOverride ??
      (_ratesCurrency == _baseCurrency ? _silverPrice : 0);

  String get _currencySymbol {
    switch (_baseCurrency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SAR':
        return '﷼';
      case 'AED':
        return 'د.إ';
      case 'MYR':
        return 'RM';
      case 'INR':
        return '₹';
      default:
        return '$_baseCurrency ';
    }
  }

  String _formatAmount(double amount) {
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Returns the complete rich computation using modern categories + legacy fields.
  _ZakatComputation _computeZakat() {
    final List<ZakatLineItem> items = <ZakatLineItem>[];

    // Cash & receivables (legacy cash + investments for now)
    final double cash =
        (_categoryAmounts[ZakatCategory.cash] ?? 0.0) +
        (double.tryParse(_cashController.text) ?? 0.0);
    if (cash > 0) {
      items.add(ZakatLineItem(category: ZakatCategory.cash, amount: cash));
    }

    // Gold (modern + legacy)
    double goldValue = _categoryAmounts[ZakatCategory.gold] ?? 0.0;
    final double legacyGoldGrams = _convertToGrams(
      double.tryParse(_goldController.text) ?? 0.0,
      _goldUnit,
    );
    goldValue += legacyGoldGrams * _effectiveGoldPrice;
    if (goldValue > 0) {
      items.add(ZakatLineItem(category: ZakatCategory.gold, amount: goldValue));
    }

    // Silver
    double silverValue = _categoryAmounts[ZakatCategory.silver] ?? 0.0;
    final double legacySilverGrams = _convertToGrams(
      double.tryParse(_silverController.text) ?? 0.0,
      _silverUnit,
    );
    silverValue += legacySilverGrams * _effectiveSilverPrice;
    if (silverValue > 0) {
      items.add(
        ZakatLineItem(category: ZakatCategory.silver, amount: silverValue),
      );
    }

    // Investments
    final double inv =
        (_categoryAmounts[ZakatCategory.investments] ?? 0) +
        (double.tryParse(_investmentsController.text) ?? 0.0);
    if (inv > 0) {
      items.add(
        ZakatLineItem(category: ZakatCategory.investments, amount: inv),
      );
    }

    // Business
    final double biz = _categoryAmounts[ZakatCategory.business] ?? 0.0;
    if (biz > 0) {
      items.add(ZakatLineItem(category: ZakatCategory.business, amount: biz));
    }

    // Livestock (special handling)
    final double livestockValue = _computeLivestockValue();
    if (livestockValue > 0) {
      items.add(
        ZakatLineItem(
          category: ZakatCategory.livestock,
          amount: livestockValue,
          // Livestock often has different rates; we use flat 2.5% on value for simplicity here
        ),
      );
    }

    // Agriculture + Other
    final double agri = _categoryAmounts[ZakatCategory.agriculture] ?? 0.0;
    if (agri > 0) {
      items.add(
        ZakatLineItem(category: ZakatCategory.agriculture, amount: agri),
      );
    }

    final double other = _categoryAmounts[ZakatCategory.other] ?? 0.0;
    if (other > 0) {
      items.add(ZakatLineItem(category: ZakatCategory.other, amount: other));
    }

    // Liabilities (deduct)
    final double liabilities =
        double.tryParse(_liabilitiesController.text) ?? 0.0;

    final double grossWealth = items.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final double netWealth = math.max(0.0, grossWealth - liabilities);

    // Nisab
    final double goldNisabValue = goldNisabGrams * _effectiveGoldPrice;
    final double silverNisabValue = silverNisabGrams * _effectiveSilverPrice;
    final bool hasMetalRates =
        goldNisabValue > 0 &&
        silverNisabValue > 0 &&
        _ratesCurrency == _baseCurrency;
    final double nisabThreshold = !hasMetalRates
        ? double.infinity
        : _nisabType == 'gold'
        ? goldNisabValue
        : silverNisabValue;

    final bool isEligible = netWealth >= nisabThreshold;
    final double zakatDue = isEligible
        ? items.fold(0.0, (sum, item) => sum + item.zakatPortion) -
              (liabilities * 0.025).clamp(
                0,
                double.infinity,
              ) // simplistic netting
        : 0.0;

    final double finalDue = zakatDue < 0 ? 0.0 : zakatDue;

    return _ZakatComputation(
      items: items,
      grossWealth: grossWealth,
      liabilities: liabilities,
      netWealth: netWealth,
      nisabThreshold: nisabThreshold,
      isEligible: isEligible,
      zakatDue: finalDue,
      goldPrice: _effectiveGoldPrice,
      silverPrice: _effectiveSilverPrice,
    );
  }

  double _computeLivestockValue() {
    // Very simplified: assign rough modern market values per head for demo power.
    // In real use, user should prefer "Other" or adjust. This gives the *feeling* of power.
    const double sheepValue = 180.0; // average ewe
    const double cowValue = 850.0;
    const double camelValue = 1800.0;

    return (_livestockSheep * sheepValue) +
        (_livestockCows * cowValue) +
        (_livestockCamels * camelValue);
  }

  // Legacy conversion (kept for old inputs)
  double _convertToGrams(double value, String unit) {
    if (unit == 'bhori') {
      return value * bhoriToGram;
    }
    return value;
  }

  // ==================== END ENGINE ====================

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final bool showAppBar = widget.showAppBar;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: showAppBar
          ? AppBar(
              title: Text(localizations.zakatCalculator),
              centerTitle: true,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                labelColor: colors.primary,
                unselectedLabelColor: colors.textMuted,
                tabs: <Tab>[
                  Tab(
                    icon: const Icon(Icons.calculate_outlined),
                    text: localizations.calculatorTab,
                  ),
                  Tab(
                    icon: const Icon(Icons.history_toggle_off_rounded),
                    text: localizations.historyTab,
                  ),
                ],
              ),
            )
          : null,
      body: showAppBar
          ? TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildCalculatorTab(theme, colors),
                _buildHistoryTab(theme, colors),
              ],
            )
          : SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: <Widget>[
                  TabBar(
                    controller: _tabController,
                    indicatorColor: colors.primary,
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textMuted,
                    tabs: <Tab>[
                      Tab(
                        icon: const Icon(Icons.calculate_outlined),
                        text: localizations.calculatorTab,
                      ),
                      Tab(
                        icon: const Icon(Icons.history_toggle_off_rounded),
                        text: localizations.historyTab,
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        _buildCalculatorTab(theme, colors),
                        _buildHistoryTab(theme, colors),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCalculatorTab(ThemeData theme, EquranColors colors) {
    final localizations = AppLocalizations.of(context)!;
    final _ZakatComputation comp = _computeZakat();
    final bool isEligible = comp.isEligible;
    final double zakatDue = comp.zakatDue;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EquranSpacing.pagePadding,
        16,
        EquranSpacing.pagePadding,
        32,
      ),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        // ==================== BEAUTIFUL HERO HEADER ====================
        EquranGradientCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  EquranIconBadge(
                    icon: Icons.volunteer_activism_rounded,
                    backgroundColor: colors.onPrimary.withAlpha(38),
                    foregroundColor: colors.onPrimary,
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          localizations.zakatAlMal,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'الزكاة',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onPrimary.withAlpha(220),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withAlpha(30),
                      borderRadius: BorderRadius.circular(EquranRadii.pill),
                    ),
                    child: Text(
                      '2.5%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localizations.purifyWealthSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ==================== LIVE MARKET + OVERRIDES (POWER) ====================
        EquranSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  EquranIconBadge(icon: Icons.trending_up_rounded, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      localizations.liveMarketRates,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (_isLoadingPrice)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      onPressed: _fetchLiveMetalPrices,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Currency selector (changeable + persisted)
              InkWell(
                onTap: _showCurrencyPicker,
                borderRadius: BorderRadius.circular(AppRadii.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '${localizations.currency}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      Text(
                        _baseCurrency,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                '${localizations.zakatCategoryGold}: $_currencySymbol${_effectiveGoldPrice.toStringAsFixed(2)}/g   •   ${localizations.zakatCategorySilver}: $_currencySymbol${_effectiveSilverPrice.toStringAsFixed(2)}/g',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _priceStatus,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                localizations.zakatDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPriceOverrideDialog(colors),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(localizations.overridePrices),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary.withAlpha(80)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_goldPriceOverride != null ||
                      _silverPriceOverride != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _goldPriceOverride = null;
                          _silverPriceOverride = null;
                        });
                      },
                      child: Text(localizations.reset),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ==================== NISAB CHOICE (MODERN) ====================
        Text(
          localizations.nisabThresholdLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildNisabChoice(
                theme,
                colors,
                label: localizations.silverDefault,
                value: 'silver',
                threshold: silverNisabGrams * _effectiveSilverPrice,
                isSelected: _nisabType == 'silver',
                onTap: () => setState(() => _nisabType = 'silver'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNisabChoice(
                theme,
                colors,
                label: localizations.gold,
                value: 'gold',
                threshold: goldNisabGrams * _effectiveGoldPrice,
                isSelected: _nisabType == 'gold',
                onTap: () => setState(() => _nisabType = 'gold'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ==================== WEALTH CATEGORIES (THE POWER) ====================
        Text(
          localizations.yourWealth,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Cash
        _buildCategoryCard(
          theme,
          colors,
          category: ZakatCategory.cash,
          controller: _cashController,
          hint: localizations.cashHint,
        ),

        // Gold
        _buildCategoryCard(
          theme,
          colors,
          category: ZakatCategory.gold,
          controller: _goldController,
          suffix: _buildUnitDropdown(
            _goldUnit,
            (v) => setState(() => _goldUnit = v),
          ),
          hint: localizations.goldHint,
        ),

        // Silver
        _buildCategoryCard(
          theme,
          colors,
          category: ZakatCategory.silver,
          controller: _silverController,
          suffix: _buildUnitDropdown(
            _silverUnit,
            (v) => setState(() => _silverUnit = v),
          ),
        ),

        // Investments (Stocks, Crypto, etc)
        _buildCategoryCard(
          theme,
          colors,
          category: ZakatCategory.investments,
          controller: _investmentsController,
          hint: localizations.investmentsHint,
        ),

        // Business Inventory
        _buildModernCategoryInput(
          theme,
          colors,
          category: ZakatCategory.business,
          hint: localizations.businessHint,
        ),

        // Livestock — the powerful one
        _buildLivestockCard(theme, colors),

        // Agriculture (simplified)
        _buildModernCategoryInput(
          theme,
          colors,
          category: ZakatCategory.agriculture,
          hint: localizations.agricultureHint,
        ),

        // Other
        _buildModernCategoryInput(
          theme,
          colors,
          category: ZakatCategory.other,
          hint: localizations.otherHint,
        ),

        const SizedBox(height: 8),

        // Liabilities
        _buildCategoryCard(
          theme,
          colors,
          category: null, // special
          controller: _liabilitiesController,
          labelOverride: localizations.liabilitiesDeduct,
          hint: localizations.liabilitiesHint,
          isDeduction: true,
        ),

        const SizedBox(height: 20),

        // ==================== STUNNING RESULT HERO ====================
        EquranGradientCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    localizations.netZakatableWealth,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isEligible
                          ? colors.onPrimary.withAlpha(30)
                          : colors.onPrimary.withAlpha(18),
                      borderRadius: BorderRadius.circular(EquranRadii.pill),
                    ),
                    child: Text(
                      isEligible
                          ? localizations.eligible
                          : localizations.belowNisab,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatAmount(comp.netWealth),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: colors.onPrimary.withAlpha(40)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        localizations.zakatDueLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onPrimaryMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAmount(zakatDue),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  if (isEligible && zakatDue > 0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.onPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                ],
              ),
              if (!isEligible && comp.netWealth > 0) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  localizations.zakatBelowNisabExplanation(
                    _formatAmount(comp.nisabThreshold),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Simple breakdown chips
        if (comp.items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: comp.items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(EquranRadii.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '${item.category.getLocalizedLabel(localizations)}: ${_formatAmount(item.amount)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),

        // Save
        FilledButton.icon(
          onPressed: zakatDue > 0.01
              ? () => _saveCurrentCalculation(comp)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EquranRadii.large),
            ),
          ),
          icon: const Icon(Icons.bookmark_added_rounded),
          label: Text(
            localizations.saveToHistory,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _resetAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(localizations.resetCalculator),
          ),
        ),
      ],
    );
  }

  // ==================== BEAUTIFUL HELPER WIDGETS ====================

  Widget _buildNisabChoice(
    ThemeData theme,
    EquranColors colors, {
    required String label,
    required String value,
    required double threshold,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EquranRadii.large),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withAlpha(12) : colors.surface,
          borderRadius: BorderRadius.circular(EquranRadii.large),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? colors.primary : colors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatAmount(threshold),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    ThemeData theme,
    EquranColors colors, {
    ZakatCategory? category,
    required TextEditingController controller,
    String? labelOverride,
    String? hint,
    Widget? suffix,
    bool isDeduction = false,
  }) {
    final String title = labelOverride ?? (category?.label ?? 'Amount');
    final IconData icon =
        category?.icon ??
        (isDeduction
            ? Icons.remove_circle_outline
            : Icons.attach_money_rounded);
    final bool isWeight =
        category == ZakatCategory.gold || category == ZakatCategory.silver;
    final String? weightUnit = category == ZakatCategory.gold
        ? (_goldUnit == 'grams' ? 'g' : 'tola')
        : (category == ZakatCategory.silver
              ? (_silverUnit == 'grams' ? 'g' : 'tola')
              : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: EquranSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                EquranIconBadge(icon: icon, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?suffix,
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText:
                    hint ??
                    (isWeight
                        ? localizations.enterWeight
                        : localizations.enterAmountInCurrency(_baseCurrency)),
                prefixText: isWeight ? null : _currencySymbol,
                suffixText: weightUnit,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EquranRadii.medium),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EquranRadii.medium),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EquranRadii.medium),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: colors.surfaceAlt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCategoryInput(
    ThemeData theme,
    EquranColors colors, {
    required ZakatCategory category,
    String? hint,
  }) {
    final double current = _categoryAmounts[category] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: EquranSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                EquranIconBadge(icon: category.icon, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (current > 0)
                  Text(
                    _formatAmount(current),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (val) {
                final double v = double.tryParse(val) ?? 0.0;
                setState(() => _categoryAmounts[category] = v);
              },
              decoration: InputDecoration(
                hintText: hint ?? localizations.amountInCurrency(_baseCurrency),
                prefixText: _currencySymbol,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EquranRadii.medium),
                  borderSide: BorderSide(color: colors.border),
                ),
                filled: true,
                fillColor: colors.surfaceAlt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivestockCard(ThemeData theme, EquranColors colors) {
    return EquranSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              EquranIconBadge(icon: ZakatCategory.livestock.icon, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ZakatCategory.livestock.getLocalizedLabel(localizations),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_computeLivestockValue() > 0)
                Text(
                  _formatAmount(_computeLivestockValue()),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            localizations.livestockSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          _buildLivestockRow(
            localizations.livestockSheepGoats,
            _livestockSheep,
            (v) => setState(() => _livestockSheep = v),
          ),
          const SizedBox(height: 8),
          _buildLivestockRow(
            localizations.livestockCowsBuffalo,
            _livestockCows,
            (v) => setState(() => _livestockCows = v),
          ),
          const SizedBox(height: 8),
          _buildLivestockRow(
            localizations.livestockCamels,
            _livestockCamels,
            (v) => setState(() => _livestockCamels = v),
          ),
        ],
      ),
    );
  }

  Widget _buildLivestockRow(
    String label,
    int count,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: count > 0 ? () => onChanged(count - 1) : null,
          visualDensity: VisualDensity.compact,
        ),
        Container(
          width: 42,
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(count + 1),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildUnitDropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButton<String>(
      value: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: const [
        DropdownMenuItem(value: 'grams', child: Text('g')),
        DropdownMenuItem(value: 'bhori', child: Text('tola')),
      ],
      underline: const SizedBox.shrink(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  void _showPriceOverrideDialog(EquranColors colors) {
    final localizations = AppLocalizations.of(context)!;
    final TextEditingController goldCtrl = TextEditingController(
      text: _effectiveGoldPrice.toStringAsFixed(2),
    );
    final TextEditingController silverCtrl = TextEditingController(
      text: _effectiveSilverPrice.toStringAsFixed(2),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.overridePrices),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: goldCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.goldPriceGram,
                prefixText: _currencySymbol,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: silverCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.silverPriceGram,
                prefixText: _currencySymbol,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _goldPriceOverride = double.tryParse(goldCtrl.text);
                _silverPriceOverride = double.tryParse(silverCtrl.text);
                _ratesCurrency = _baseCurrency;
              });
              Navigator.pop(ctx);
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentCalculation(_ZakatComputation comp) async {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();

    final ZakatRecord rec = ZakatRecord(
      id: id,
      date: DateTime.now(),
      cash: double.tryParse(_cashController.text) ?? 0.0,
      investments: double.tryParse(_investmentsController.text) ?? 0.0,
      goldGrams: _convertToGrams(
        double.tryParse(_goldController.text) ?? 0.0,
        _goldUnit,
      ),
      goldPrice: comp.goldPrice,
      silverGrams: _convertToGrams(
        double.tryParse(_silverController.text) ?? 0.0,
        _silverUnit,
      ),
      silverPrice: comp.silverPrice,
      liabilities: double.tryParse(_liabilitiesController.text) ?? 0.0,
      nisabType: _nisabType,
      nisabValue: comp.nisabThreshold,
      zakatDue: comp.zakatDue,
      detailsJson: <String, dynamic>{
        'richItems': comp.items.map((e) => e.toJson()).toList(),
        'livestock': {
          'sheep': _livestockSheep,
          'cows': _livestockCows,
          'camels': _livestockCamels,
        },
        'currency': _baseCurrency,
      },
    );

    await ZakatHistoryDB.instance.saveRecord(rec);

    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.zakatSavedLedger),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(1);
    }
  }

  void _resetAll() {
    setState(() {
      _cashController.clear();
      _investmentsController.clear();
      _goldController.clear();
      _silverController.clear();
      _liabilitiesController.clear();

      _categoryAmounts.updateAll((_, val) => 0.0);
      _livestockSheep = 0;
      _livestockCows = 0;
      _livestockCamels = 0;
      _goldPriceOverride = null;
      _silverPriceOverride = null;
    });
  }

  // ==================== CURRENCY SUPPORT ====================

  static const List<String> supportedZakatCurrencies = <String>[
    'USD',
    'EUR',
    'GBP',
    'SAR',
    'AED',
    'IDR',
    'INR',
    'MYR',
    'PKR',
    'BDT',
    'TRY',
    'CAD',
    'AUD',
  ];

  Future<void> _changeBaseCurrency(String newCurrency) async {
    if (newCurrency == _baseCurrency) return;
    setState(() {
      _baseCurrency = newCurrency;
    });
    await SettingsDB().put('zakat_currency', newCurrency);
    await _fetchLiveMetalPrices();
  }

  void _showCurrencyPicker() {
    final localizations = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(localizations.selectCurrency),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: _baseCurrency,
            onChanged: (String? val) {
              if (val != null) {
                Navigator.pop(ctx);
                _changeBaseCurrency(val);
              }
            },
            child: ListView(
              shrinkWrap: true,
              children: supportedZakatCurrencies.map((String c) {
                return RadioListTile<String>(title: Text(c), value: c);
              }).toList(),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, EquranColors colors) {
    final localizations = AppLocalizations.of(context)!;
    return ValueListenableBuilder<dynamic>(
      valueListenable: ZakatHistoryDB.instance.listener,
      builder: (BuildContext context, dynamic val, Widget? child) {
        final List<ZakatRecord> records = ZakatHistoryDB.instance
            .getAllRecords();

        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.noHistoricalCalculations,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.savedRecordsAppearHere,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (BuildContext context, int index) {
            final ZakatRecord rec = records[index];
            final String dateStr =
                '${rec.date.day}/${rec.date.month}/${rec.date.year}';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                side: BorderSide(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          localizations.calculationOnDate(dateStr),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () async {
                            await ZakatHistoryDB.instance.deleteRecord(rec.id);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    _buildHistoryRow(
                      localizations.historyLiquidCash,
                      _formatAmount(rec.cash),
                    ),
                    _buildHistoryRow(
                      localizations.historyInvestments,
                      _formatAmount(rec.investments),
                    ),
                    _buildHistoryRow(
                      localizations.historyGoldGrams(
                        rec.goldGrams.toStringAsFixed(1),
                      ),
                      _formatAmount(rec.goldGrams * rec.goldPrice),
                    ),
                    _buildHistoryRow(
                      localizations.historySilverGrams(
                        rec.silverGrams.toStringAsFixed(1),
                      ),
                      _formatAmount(rec.silverGrams * rec.silverPrice),
                    ),
                    _buildHistoryRow(
                      localizations.historyLiabilities,
                      '-${_formatAmount(rec.liabilities)}',
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          localizations.historyZakatDue,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          _formatAmount(rec.zakatDue),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(localizations.zakatPaidDistributed),
                        Row(
                          children: <Widget>[
                            Text(
                              _formatAmount(rec.zakatPaid),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _showPaidAmountDialog(context, rec),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaidAmountDialog(BuildContext context, ZakatRecord record) {
    final localizations = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: record.zakatPaid.toString(),
    );
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.updateZakatPaidAmount),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: localizations.enterPaidAmountUsd,
              prefixText: _currencySymbol,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                final double? amount = double.tryParse(controller.text);
                if (amount != null) {
                  await ZakatHistoryDB.instance.updatePaidAmount(
                    record.id,
                    amount,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(localizations.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 13)),
          Text(
            val,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
