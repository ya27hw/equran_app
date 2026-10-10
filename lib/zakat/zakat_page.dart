import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:equran/backend/settings_db.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/widgets/app_selection_dialog.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/segmented_control.dart';
import 'package:equran/zakat/zakat_db.dart';
import 'package:equran/zakat/zakat_widgets.dart';
import 'package:equran/zakat/metal_price_service.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
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
    final dynamic savedCurrency = SettingsDB().get('zakat_currency');
    _baseCurrency = savedCurrency is String && savedCurrency.isNotEmpty
        ? savedCurrency
        : 'USD';
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String time = DateFormat.yMMMd(
      localizations.localeName,
    ).add_jm().format(snapshot.fetchedAt.toLocal());
    return snapshot.isStale
        ? localizations.ratesStaleStatus(snapshot.source, time)
        : localizations.ratesLiveStatus(snapshot.source, time);
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
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    return RedesignSubpage(
      title: l.zakatCalculator,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EquranSpacing.pagePadding,
              0,
              EquranSpacing.pagePadding,
              12,
            ),
            child: ListenableBuilder(
              listenable: _tabController,
              builder: (BuildContext context, Widget? child) =>
                  RedesignSegmentedControl(
                    labels: <String>[l.calculatorTab, l.historyTab],
                    icons: const <Widget?>[
                      DesignIcon('calc', size: 18),
                      DesignIcon('clock', size: 18),
                    ],
                    selectedIndex: _tabController.index,
                    onChanged: _tabController.animateTo,
                  ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: tokens.hair),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[_buildCalculatorTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
    child: RedesignEyebrow(text),
  );

  Widget _buildCalculatorTab() {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    final _ZakatComputation comp = _computeZakat();
    final bool isEligible = comp.isEligible;
    final double zakatDue = comp.zakatDue;
    final bool nisabKnown = comp.nisabThreshold.isFinite;
    final TextStyle captionStyle = TextStyle(
      fontSize: 12.5,
      height: 1.4,
      color: tokens.muted,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EquranSpacing.pagePadding,
        16,
        EquranSpacing.pagePadding,
        32,
      ),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        ZakatIntroHero(
          title: l.zakatAlMal,
          arabicTitle: 'الزكاة',
          rateLabel: '2.5%',
          subtitle: l.purifyWealthSubtitle,
        ),
        const SizedBox(height: 16),

        // Live market rates and manual overrides.
        ZakatCard(
          icon: const DesignIcon('bars'),
          title: l.liveMarketRates,
          trailing: _isLoadingPrice
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton44(
                  icon: Icons.refresh_rounded,
                  tooltip: l.liveMarketRates,
                  ghost: true,
                  onPressed: _fetchLiveMetalPrices,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ZakatCurrencyButton(
                label: l.currency,
                currency: _baseCurrency,
                onPressed: _showCurrencyPicker,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: ZakatRateTile(
                      label: l.zakatCategoryGold,
                      value:
                          '$_currencySymbol${_effectiveGoldPrice.toStringAsFixed(2)}/g',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZakatRateTile(
                      label: l.zakatCategorySilver,
                      value:
                          '$_currencySymbol${_effectiveSilverPrice.toStringAsFixed(2)}/g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_priceStatus, style: captionStyle),
              const SizedBox(height: 4),
              Text(l.zakatDisclaimer, style: captionStyle),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPriceOverrideDialog,
                      icon: const DesignIcon('edit', size: 16),
                      label: Text(l.overridePrices),
                      style: readerOutlinedButtonStyle(context).copyWith(
                        minimumSize: const WidgetStatePropertyAll<Size>(
                          Size(0, 44),
                        ),
                      ),
                    ),
                  ),
                  if (_goldPriceOverride != null ||
                      _silverPriceOverride != null) ...<Widget>[
                    const SizedBox(width: 8),
                    TextButton(
                      style: readerNoticeButtonStyle(context),
                      onPressed: () {
                        setState(() {
                          _goldPriceOverride = null;
                          _silverPriceOverride = null;
                        });
                      },
                      child: Text(l.reset),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Nisab choice.
        _sectionLabel(l.nisabThresholdLabel),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ZakatNisabChoice(
                  label: l.silverDefault,
                  amount: _formatAmount(
                    silverNisabGrams * _effectiveSilverPrice,
                  ),
                  selected: _nisabType == 'silver',
                  onTap: () => setState(() => _nisabType = 'silver'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ZakatNisabChoice(
                  label: l.gold,
                  amount: _formatAmount(goldNisabGrams * _effectiveGoldPrice),
                  selected: _nisabType == 'gold',
                  onTap: () => setState(() => _nisabType = 'gold'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Wealth categories.
        _sectionLabel(l.yourWealth),
        _buildCategoryCard(
          category: ZakatCategory.cash,
          controller: _cashController,
          hint: l.cashHint,
        ),
        _buildCategoryCard(
          category: ZakatCategory.gold,
          controller: _goldController,
          suffix: ZakatUnitPicker(
            value: _goldUnit,
            onChanged: (String v) => setState(() => _goldUnit = v),
          ),
          hint: l.goldHint,
        ),
        _buildCategoryCard(
          category: ZakatCategory.silver,
          controller: _silverController,
          suffix: ZakatUnitPicker(
            value: _silverUnit,
            onChanged: (String v) => setState(() => _silverUnit = v),
          ),
        ),
        _buildCategoryCard(
          category: ZakatCategory.investments,
          controller: _investmentsController,
          hint: l.investmentsHint,
        ),
        _buildModernCategoryInput(
          category: ZakatCategory.business,
          hint: l.businessHint,
        ),
        _buildLivestockCard(),
        _buildModernCategoryInput(
          category: ZakatCategory.agriculture,
          hint: l.agricultureHint,
        ),
        _buildModernCategoryInput(
          category: ZakatCategory.other,
          hint: l.otherHint,
        ),
        _buildCategoryCard(
          category: null,
          controller: _liabilitiesController,
          labelOverride: l.liabilitiesDeduct,
          hint: l.liabilitiesHint,
          isDeduction: true,
        ),

        const SizedBox(height: 12),

        // Result.
        ZakatResultHero(
          netLabel: l.netZakatableWealth,
          netAmount: _formatAmount(comp.netWealth),
          // Without gold and silver rates there is no nisab figure (the
          // threshold is infinite), so the verdict is unknown, not "below" and
          // the due amount is not a result: show a neutral state and a dash.
          statusLabel: !nisabKnown
              ? l.zakatNisabNotChecked
              : isEligible
              ? l.eligible
              : l.belowNisab,
          eligible: nisabKnown && isEligible,
          dueLabel: l.zakatDueLabel,
          dueAmount: nisabKnown ? _formatAmount(zakatDue) : '\u2014',
          showHeart: nisabKnown && isEligible && zakatDue > 0,
          note: !nisabKnown
              ? l.zakatNisabNeedsRates
              : !isEligible && comp.netWealth > 0
              ? l.zakatBelowNisabExplanation(_formatAmount(comp.nisabThreshold))
              : null,
        ),

        if (comp.items.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          ZakatBreakdownList(
            rows: <(String, String)>[
              for (final ZakatLineItem item in comp.items)
                (
                  item.category.getLocalizedLabel(l),
                  _formatAmount(item.amount),
                ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: zakatDue > 0.01
              ? () => _saveCurrentCalculation(comp)
              : null,
          style: readerFilledButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 52)),
          ),
          icon: const DesignIcon('bookmark', size: 18),
          label: Text(l.saveToHistory),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _resetAll,
            style: readerTextButtonStyle(context),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l.resetCalculator),
          ),
        ),
      ],
    );
  }

  // ==================== Presentation helpers ====================

  /// The shared look of every amount field.
  InputDecoration _amountDecoration({
    required String hint,
    String? prefixText,
    String? suffixText,
  }) => readerInputDecoration(
    context,
    hint: hint,
    suffixText: suffixText,
    radius: EquranRadii.large,
  ).copyWith(prefixText: prefixText);

  Widget _buildCategoryCard({
    ZakatCategory? category,
    required TextEditingController controller,
    String? labelOverride,
    String? hint,
    Widget? suffix,
    bool isDeduction = false,
  }) {
    final String title =
        labelOverride ?? (category?.getLocalizedLabel(localizations) ?? '');
    final IconData icon =
        category?.icon ??
        (isDeduction
            ? Icons.remove_circle_outline
            : Icons.attach_money_rounded);
    final bool isWeight =
        category == ZakatCategory.gold || category == ZakatCategory.silver;
    final String? weightUnit = category == ZakatCategory.gold
        ? (_goldUnit == 'grams' ? 'g' : localizations.unitTola)
        : (category == ZakatCategory.silver
              ? (_silverUnit == 'grams' ? 'g' : localizations.unitTola)
              : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ZakatCard(
        icon: Icon(icon),
        title: title,
        trailing: suffix,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
            fontSize: 16,
            fontVariations: [FontVariation('opsz', 16)],
          ),
          decoration: _amountDecoration(
            hint:
                hint ??
                (isWeight
                    ? localizations.enterWeight
                    : localizations.enterAmountInCurrency(_baseCurrency)),
            prefixText: isWeight ? null : _currencySymbol,
            suffixText: weightUnit,
          ),
        ),
      ),
    );
  }

  Widget _buildModernCategoryInput({
    required ZakatCategory category,
    String? hint,
  }) {
    final double current = _categoryAmounts[category] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ZakatCard(
        icon: Icon(category.icon),
        title: category.getLocalizedLabel(localizations),
        trailing: current > 0 ? ZakatAmountLabel(_formatAmount(current)) : null,
        child: TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (String val) {
            final double v = double.tryParse(val) ?? 0.0;
            setState(() => _categoryAmounts[category] = v);
          },
          style: const TextStyle(
            fontSize: 16,
            fontVariations: [FontVariation('opsz', 16)],
          ),
          decoration: _amountDecoration(
            hint: hint ?? localizations.amountInCurrency(_baseCurrency),
            prefixText: _currencySymbol,
          ),
        ),
      ),
    );
  }

  /// Livestock zakat follows count-based schedules per animal type, which this
  /// calculator does not carry from a reviewed source. Rather than estimate a
  /// value per head, it says so and leaves livestock out of the total.
  Widget _buildLivestockCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ZakatCard(
        icon: Icon(ZakatCategory.livestock.icon),
        title: ZakatCategory.livestock.getLocalizedLabel(localizations),
        subtitle: localizations.zakatLivestockNotCalculated,
        child: const SizedBox.shrink(),
      ),
    );
  }

  void _showPriceOverrideDialog() {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final TextEditingController goldCtrl = TextEditingController(
      text: _effectiveGoldPrice.toStringAsFixed(2),
    );
    final TextEditingController silverCtrl = TextEditingController(
      text: _effectiveSilverPrice.toStringAsFixed(2),
    );

    showReaderDialog<void>(
      context: context,
      builder: (BuildContext ctx) => ReaderDialog(
        title: l.overridePrices,
        icon: const DesignIcon('edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextField(
                controller: goldCtrl,
                keyboardType: TextInputType.number,
                decoration: readerInputDecoration(
                  ctx,
                  label: l.goldPriceGram(_baseCurrency),
                ).copyWith(prefixText: _currencySymbol),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: silverCtrl,
              keyboardType: TextInputType.number,
              decoration: readerInputDecoration(
                ctx,
                label: l.silverPriceGram(_baseCurrency),
              ).copyWith(prefixText: _currencySymbol),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: readerTextButtonStyle(ctx),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: readerFilledButtonStyle(ctx),
            onPressed: () {
              setState(() {
                _goldPriceOverride = double.tryParse(goldCtrl.text);
                _silverPriceOverride = double.tryParse(silverCtrl.text);
                _ratesCurrency = _baseCurrency;
              });
              Navigator.pop(ctx);
            },
            child: Text(l.save),
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
    final AppLocalizations l = AppLocalizations.of(context)!;
    showReaderDialog<String>(
      context: context,
      builder: (BuildContext ctx) => ReaderChoiceDialog<String>(
        title: l.selectCurrency,
        icon: const DesignIcon('calc'),
        selectedValue: _baseCurrency,
        options: <AppSelectionOption<String>>[
          for (final String c in supportedZakatCurrencies)
            AppSelectionOption<String>(value: c, title: c),
        ],
      ),
    ).then((String? val) {
      if (val != null) _changeBaseCurrency(val);
    });
  }

  Widget _buildHistoryTab() {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<dynamic>(
      valueListenable: ZakatHistoryDB.instance.listener,
      builder: (BuildContext context, dynamic val, Widget? child) {
        final List<ZakatRecord> records = ZakatHistoryDB.instance
            .getAllRecords();

        if (records.isEmpty) {
          return ZakatEmptyState(
            title: l.noHistoricalCalculations,
            hint: l.savedRecordsAppearHere,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            EquranSpacing.pagePadding,
            16,
            EquranSpacing.pagePadding,
            32,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final ZakatRecord rec = records[index];
            final String dateStr =
                '${rec.date.day}/${rec.date.month}/${rec.date.year}';
            return ZakatHistoryCard(
              title: l.calculationOnDate(dateStr),
              rows: <(String, String)>[
                (l.historyLiquidCash, _formatAmount(rec.cash)),
                (l.historyInvestments, _formatAmount(rec.investments)),
                (
                  l.historyGoldGrams(rec.goldGrams.toStringAsFixed(1)),
                  _formatAmount(rec.goldGrams * rec.goldPrice),
                ),
                (
                  l.historySilverGrams(rec.silverGrams.toStringAsFixed(1)),
                  _formatAmount(rec.silverGrams * rec.silverPrice),
                ),
                (l.historyLiabilities, '-${_formatAmount(rec.liabilities)}'),
              ],
              dueLabel: l.historyZakatDue,
              dueAmount: _formatAmount(rec.zakatDue),
              paidLabel: l.zakatPaidDistributed,
              paidAmount: _formatAmount(rec.zakatPaid),
              deleteTooltip: l.delete,
              editTooltip: l.edit,
              onDelete: () => _confirmDeleteRecord(rec),
              onEditPaid: () => _showPaidAmountDialog(context, rec),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteRecord(ZakatRecord rec) async {
    final bool? confirmed = await showReaderDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppLocalizations l = AppLocalizations.of(ctx)!;
        return ReaderConfirmDialog(
          title: l.zakatDeleteRecordQuestion,
          body: l.zakatDeleteRecordBody,
          icon: const DesignIcon('trash'),
          cancelLabel: l.cancel,
          confirmLabel: l.delete,
          destructive: true,
        );
      },
    );
    if (confirmed == true) {
      await ZakatHistoryDB.instance.deleteRecord(rec.id);
    }
  }

  void _showPaidAmountDialog(BuildContext context, ZakatRecord record) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: record.zakatPaid.toString(),
    );
    showReaderDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ReaderDialog(
          title: l.updateZakatPaidAmount,
          icon: const DesignIcon('edit'),
          content: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: readerInputDecoration(
                context,
                hint: l.enterPaidAmountInCurrency(_baseCurrency),
              ).copyWith(prefixText: _currencySymbol),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: readerTextButtonStyle(context),
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            FilledButton(
              style: readerFilledButtonStyle(context),
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
              child: Text(l.save),
            ),
          ],
        );
      },
    );
  }
}
