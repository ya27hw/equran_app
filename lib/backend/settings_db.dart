import 'package:quran/quran.dart' as quran;
import 'base_db.dart';
import 'daily_tools_config.dart';

class SettingsDB extends BaseDB {
  // Private constructor
  SettingsDB._privateConstructor() : super('settings');

  // Singleton instance
  static final SettingsDB _instance = SettingsDB._privateConstructor();

  // Factory constructor to return the singleton instance
  factory SettingsDB() {
    return _instance;
  }

  @override
  Future<void> initBox() async {
    await super.initBox();
    final String activeStyle = quranScriptStyle;
    quran.setQuranTextAssetBase('assets/data/quran/text/$activeStyle');
  }

  /// Old AMOLED selections become the default accent with pure black enabled.
  /// Keep this fallback for older backups as well as existing installations.
  bool get pureBlackBackground {
    final dynamic saved = get('pureBlackBackground');
    return saved is bool ? saved : get('themeScheme') == 'black';
  }

  /// Getter for tracking the script style preference key
  String get quranScriptStyle {
    final dynamic raw = get('quran_script_style', defaultValue: 'qpc-hafs');
    final String style = raw is String ? raw : 'qpc-hafs';
    return style == 'uthmani' ? 'qpc-hafs' : style;
  }

  /// Setter for tracking the script style preference key
  Future<void> setQuranScriptStyle(String style) async {
    final String normalizedStyle = style == 'uthmani' ? 'qpc-hafs' : style;
    await put('quran_script_style', normalizedStyle);
    quran.setQuranTextAssetBase('assets/data/quran/text/$normalizedStyle');
    await quran.initializeQuran();
  }

  /// Get visible daily tools from settings
  List<DailyToolType> getVisibleDailyTools() {
    final dynamic saved = get('daily_tools_visible');
    if (saved is! List) {
      return List<DailyToolType>.from(DailyToolType.defaultTools);
    }
    return List<DailyToolType>.from(
      saved.map(
        (e) => DailyToolType.values.firstWhere(
          (t) => t.name == e,
          orElse: () => DailyToolType.quran,
        ),
      ),
    );
  }

  /// Save visible daily tools to settings
  Future<void> setVisibleDailyTools(List<DailyToolType> tools) async {
    await put('daily_tools_visible', tools.map((t) => t.name).toList());
  }
}
