import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/l10n/app_localizations.dart';

class ZakahCalculatorPage extends StatefulWidget {
  const ZakahCalculatorPage({super.key});

  @override
  State<ZakahCalculatorPage> createState() => _ZakahCalculatorPageState();
}

class _ZakahCalculatorPageState extends State<ZakahCalculatorPage> {
  final TextEditingController _cashController = TextEditingController(
    text: '0',
  );
  final TextEditingController _goldController = TextEditingController(
    text: '0',
  );
  final TextEditingController _silverController = TextEditingController(
    text: '0',
  );
  final TextEditingController _assetsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _debtsController = TextEditingController(
    text: '0',
  );

  double _cash = 0;
  double _gold = 0;
  double _silver = 0;
  double _assets = 0;
  double _debts = 0;

  final double _nisab =
      200.0; // The threshold mentioned in localization "totalZakahWealth"

  @override
  void initState() {
    super.initState();
    _cashController.addListener(_calculate);
    _goldController.addListener(_calculate);
    _silverController.addListener(_calculate);
    _assetsController.addListener(_calculate);
    _debtsController.addListener(_calculate);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _assetsController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _cash = double.tryParse(_cashController.text) ?? 0;
      _gold = double.tryParse(_goldController.text) ?? 0;
      _silver = double.tryParse(_silverController.text) ?? 0;
      _assets = double.tryParse(_assetsController.text) ?? 0;
      _debts = double.tryParse(_debtsController.text) ?? 0;
    });
  }

  // Translations
  String _tTitle(String lang) => switch (lang) {
    'ar' => 'حاسبة الزكاة',
    'fa' => 'محاسبه زکات',
    'de' => 'Zakat-Rechner',
    'bn' => 'যাকাত ক্যালকুলেটর',
    'id' => 'Kalkulator Zakat',
    'tr' => 'Zekat Hesaplama',
    'ur' => 'زکوٰۃ کیلکولیٹر',
    _ => 'Zakah Calculator',
  };

  String _tCash(String lang) => switch (lang) {
    'ar' => 'النقود والحسابات البنكية',
    'fa' => 'پول نقد و حساب‌های بانکی',
    'de' => 'Bargeld & Bankguthaben',
    'bn' => 'নগদ ও ব্যাংক হিসাব',
    'id' => 'Uang Tunai & Tabungan',
    'tr' => 'Nakit & Banka Hesapları',
    'ur' => 'نقد اور بینک اکاؤنٹس',
    _ => 'Cash & Bank Accounts',
  };

  String _tGold(String lang) => switch (lang) {
    'ar' => 'قيمة الذهب المملوك',
    'fa' => 'ارزش طلای تحت مالکیت',
    'de' => 'Wert des Goldbesitzes',
    'bn' => 'স্বর্ণের মূল্য',
    'id' => 'Nilai Emas',
    'tr' => 'Altın Değeri',
    'ur' => 'سونے کی مالیت',
    _ => 'Gold Value',
  };

  String _tSilver(String lang) => switch (lang) {
    'ar' => 'قيمة الفضة المملوكة',
    'fa' => 'ارزش نقره تحت مالکیت',
    'de' => 'Wert des Silberbesitzes',
    'bn' => 'رুপার মূল্য',
    'id' => 'Nilai Perak',
    'tr' => 'Gümüş Değeri',
    'ur' => 'چاندی کی مالیت',
    _ => 'Silver Value',
  };

  String _tAssets(String lang) => switch (lang) {
    'ar' => 'أصول واستثمارات أخرى',
    'fa' => 'سایر دارایی‌ها و سرمایه‌گذاری‌ها',
    'de' => 'Sonstige Vermögenswerte & Investitionen',
    'bn' => 'অন্যান্য সম্পদ ও বিনিয়োগ',
    'id' => 'Aset & Investasi Lainnya',
    'tr' => 'Diğer Varlıklar & Yatırımlar',
    'ur' => 'دیگر اثاثے اور سرمایہ کاری',
    _ => 'Other Assets & Investments',
  };

  String _tDebts(String lang) => switch (lang) {
    'ar' => 'الديون والالتزامات المستحقة',
    'fa' => 'بدهی‌ها و تعهدات مالی',
    'de' => 'Schulden & Verbindlichkeiten',
    'bn' => 'ঋণ ও দায়বদ্ধতা',
    'id' => 'Hutang & Kewajiban',
    'tr' => 'Borçlar & Yükümlülükler',
    'ur' => 'قرض اور واجبات',
    _ => 'Liabilities & Debts',
  };

  String _tTotalAssets(String lang) => switch (lang) {
    'ar' => 'إجمالي الأصول',
    'fa' => 'کل دارایی‌ها',
    'de' => 'Gesamtvermögen',
    'bn' => 'মোট সম্পদ',
    'id' => 'Total Aset',
    'tr' => 'Toplam Varlıklar',
    'ur' => 'کل اثاثے',
    _ => 'Total Assets',
  };

  String _tNetWealth(String lang) => switch (lang) {
    'ar' => 'صافي الثروة',
    'fa' => 'ثروت خالص',
    'de' => 'Nettovermögen',
    'bn' => 'নিট সম্পদ',
    'id' => 'Kekayaan Bersih',
    'tr' => 'Net Servet',
    'ur' => 'صافی دولت',
    _ => 'Net Wealth',
  };

  String _tNisabThreshold(String lang) => switch (lang) {
    'ar' => 'حد النصاب',
    'fa' => 'حد نصاب',
    'de' => 'Nisab-Grenze',
    'bn' => 'নিসাব সীমা',
    'id' => 'Ambang Nisab',
    'tr' => 'Nisap Eşiği',
    'ur' => 'نصاب کی حد',
    _ => 'Nisab Threshold',
  };

  String _tZakahDue(String lang) => switch (lang) {
    'ar' => 'الزكاة المستحقة',
    'fa' => 'زکات مستحق پرداخت',
    'de' => 'Fällige Zakat',
    'bn' => 'প্রদেয় যাকাত',
    'id' => 'Zakat yang Wajib Dibayar',
    'tr' => 'Ödenmesi Gereken Zekat',
    'ur' => 'واجب الادا زکوٰۃ',
    _ => 'Zakah Due',
  };

  String _tZakahRate(String lang) => switch (lang) {
    'ar' => 'نسبة الزكاة (٢.٥٪)',
    'fa' => 'نرخ زکات (۲.۵٪)',
    'de' => 'Zakat-Satz (2,5%)',
    'bn' => 'যাকাতের হার (২.৫%)',
    'id' => 'Tarif Zakat (2.5%)',
    'tr' => 'Zekat Oranı (%2.5)',
    'ur' => 'زکوٰۃ کی شرح (2.5%)',
    _ => 'Zakah Rate (2.5%)',
  };

  String _tNisabMet(String lang) => switch (lang) {
    'ar' => 'بلغ النصاب',
    'fa' => 'به حد نصاب رسیده',
    'de' => 'Nisab erreicht',
    'bn' => 'নিসাব পূর্ণ হয়েছে',
    'id' => 'Memenuhi Nisab',
    'tr' => 'Nisaba Ulaştı',
    'ur' => 'نصاب پورا ہے',
    _ => 'Nisab Met',
  };

  String _tNisabNotMet(String lang) => switch (lang) {
    'ar' => 'لم يبلغ النصاب',
    'fa' => 'به حد نصاب نرسیده',
    'de' => 'Nisab nicht erreicht',
    'bn' => 'নিসাব পূর্ণ হয়নি',
    'id' => 'Tidak Memenuhi Nisab',
    'tr' => 'Nisaba Ulaşmadı',
    'ur' => 'نصاب پورا نہیں ہے',
    _ => 'Nisab Not Met',
  };

  String _tNote(String lang) => switch (lang) {
    'ar' =>
      'ملاحظة: تجب الزكاة بنسبة ٢.٥٪ إذا بلغت ثروتك الصافية النصاب وحال عليها الحول الهجري.',
    'fa' =>
      'توجه: اگر ثروت خالص شما از حد نصاب بیشتر باشد و یک سال قمری کامل از آن گذشته باشد، پرداخت زکات (۲.۵٪) واجب است.',
    'de' =>
      'Hinweis: Die Zakat (2,5%) ist verpflichtend, wenn Ihr Nettovermögen die Nisab-Grenze überschreitet und sich ein ganzes Hijri-Jahr in Ihrem Besitz befindet.',
    'bn' =>
      'দ্রষ্টব্য: আপনার নিট সম্পদ নিসাব সীমা অতিক্রম করলে এবং এক বছর থাকলে ২.৫% যাকাত প্রদেয় হবে।',
    'id' =>
      'Catatan: Zakat wajib (2.5%) jika kekayaan bersih Anda melebihi ambang Nisab dan telah dimiliki selama satu tahun Hijriah.',
    'tr' =>
      'Not: Net servetiniz nisap eşiğini aşarsa ve üzerinden bir Hicri yıl geçerse %2.5 zekat ödemeniz gerekir.',
    'ur' =>
      'نوٹ: اگر آپ کی صافی دولت نصاب کی حد سے زیادہ ہو اور اس پر ایک ہجری سال گزر چکا ہو تو 2.5% زکوٰۃ فرض ہے۔',
    _ =>
      'Note: Zakah (2.5%) is obligatory if your net wealth exceeds the Nisab threshold and has been held for a full Hijri year.',
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String lang = localizations.localeName.split('_').first.toLowerCase();
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);

    final double totalAssets = _cash + _gold + _silver + _assets;
    final double netWealth = totalAssets - _debts;
    final bool nisabMet = netWealth >= _nisab;
    final double zakahDue = nisabMet ? netWealth * 0.025 : 0.0;

    return RedesignSubpage(
      title: _tTitle(lang),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Results Card
                  _buildResultsCard(
                    colors,
                    theme,
                    lang,
                    netWealth,
                    zakahDue,
                    nisabMet,
                  ),
                  const SizedBox(height: 20),

                  // Inputs Card
                  Card(
                    color: colors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.border.withAlpha(120)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            colors,
                            theme,
                            _cashController,
                            _tCash(lang),
                            Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            colors,
                            theme,
                            _goldController,
                            _tGold(lang),
                            Icons.workspace_premium_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            colors,
                            theme,
                            _silverController,
                            _tSilver(lang),
                            Icons.monetization_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            colors,
                            theme,
                            _assetsController,
                            _tAssets(lang),
                            Icons.trending_up_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            colors,
                            theme,
                            _debtsController,
                            _tDebts(lang),
                            Icons.payment_outlined,
                            isDebt: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calculation Breakdown Card
                  Card(
                    color: colors.surfaceSoft,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildBreakdownRow(
                            colors,
                            theme,
                            _tTotalAssets(lang),
                            totalAssets,
                          ),
                          const Divider(height: 16),
                          _buildBreakdownRow(
                            colors,
                            theme,
                            _tDebts(lang),
                            _debts,
                            isDebt: true,
                          ),
                          const Divider(height: 16),
                          _buildBreakdownRow(
                            colors,
                            theme,
                            _tNetWealth(lang),
                            netWealth,
                            isBold: true,
                          ),
                          const Divider(height: 16),
                          _buildBreakdownRow(
                            colors,
                            theme,
                            _tNisabThreshold(lang),
                            _nisab,
                            valueColor: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nisab Met warning/info from arb localization
                  if (!nisabMet && netWealth > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withAlpha(120)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              localizations.totalZakahWealth,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Guidelines Note
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _tNote(lang),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(
    EquranColors colors,
    ThemeData theme,
    String lang,
    double netWealth,
    double zakahDue,
    bool nisabMet,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryStrong],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.calculate_outlined,
              size: 130,
              color: colors.onPrimary.withAlpha(25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tZakahDue(lang).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary.withAlpha(210),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: nisabMet
                            ? Colors.green.withAlpha(60)
                            : colors.onPrimary.withAlpha(35),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: nisabMet
                              ? Colors.greenAccent
                              : colors.onPrimary.withAlpha(50),
                        ),
                      ),
                      child: Text(
                        nisabMet ? _tNisabMet(lang) : _tNisabNotMet(lang),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  zakahDue.toStringAsFixed(2),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tZakahRate(lang),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withAlpha(200),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    EquranColors colors,
    ThemeData theme,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isDebt = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isDebt ? Colors.redAccent : colors.primary,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: colors.surfaceSoft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withAlpha(120)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withAlpha(120)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    EquranColors colors,
    ThemeData theme,
    String label,
    double value, {
    bool isBold = false,
    bool isDebt = false,
    Color? valueColor,
  }) {
    final TextStyle? style = isBold
        ? theme.textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          );

    final String valuePrefix = isDebt && value > 0 ? '-' : '';
    final Color effectiveValueColor =
        valueColor ??
        (isDebt && value > 0
            ? Colors.redAccent
            : (isBold ? colors.primary : colors.textPrimary));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '$valuePrefix${value.toStringAsFixed(2)}',
          style: style?.copyWith(
            color: effectiveValueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
