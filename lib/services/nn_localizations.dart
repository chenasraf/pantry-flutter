import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart' as date_symbol_data_custom;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbols.dart' as intl_symbols;
import 'package:intl/intl.dart' as intl;

/// Full Nynorsk (nn) framework localizations.
///
/// `flutter_localizations` and `intl` ship Norwegian only as Bokmål (`nb`);
/// there is no `nn` data at all, and building a [GlobalMaterialLocalizations]
/// subclass for `nn` crashes because `intl.DateFormat('…', 'nn')` throws
/// `Invalid locale "nn"`. To support `nn` properly (rather than falling back to
/// the related-but-different Bokmål), we:
///
///  1. Register `nn` date-formatting symbols and patterns with `intl` via
///     [registerNnLocaleData], so `DateFormat.localeExists('nn')` becomes true.
///  2. Provide [NnMaterialLocalizations] / [NnCupertinoLocalizations] with the
///     UI strings translated into Nynorsk.
///
/// The Nynorsk strings and date symbols below were machine-translated from the
/// official Bokmål bundle and need a native-speaker review pass before they can
/// be considered final (weekday names, s-passive hints like `Skjulast`/`Visast`,
/// and the `Oppgi …` time announcements are the most likely to need tweaks).

const _nnMaterialDelegate = _NnMaterialLocalizationsDelegate();
const _nnCupertinoDelegate = _NnCupertinoLocalizationsDelegate();

/// Delegates to prepend (before the Global* delegates) so `nn` resolves to the
/// Nynorsk bundles below instead of being reported as unsupported.
const nnLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  _nnMaterialDelegate,
  _nnCupertinoDelegate,
];

bool _nnRegistered = false;

/// Registers Nynorsk date-formatting data with `intl`. Idempotent. Must run
/// before either delegate builds a `DateFormat`, so we call it from app startup
/// and again (cheaply) inside each delegate's `load` as a safety net.
void registerNnLocaleData() {
  if (_nnRegistered) return;
  // Load the bundled standard-locale data first. initializeDateFormattingCustom
  // resets the symbol/pattern maps to empty when they are still uninitialized,
  // which would drop every other locale (en, nb, …). Loading the standard data
  // first turns that reset into a no-op, and our nn entry is then layered on top.
  initializeDateFormatting();
  date_symbol_data_custom.initializeDateFormattingCustom(
    locale: 'nn',
    symbols: intl_symbols.DateSymbols.deserializeFromMap(_nnDateSymbols),
    patterns: _nnDatePatterns,
  );
  _nnRegistered = true;
}

class _NnMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _NnMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'nn';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    registerNnLocaleData();
    const localeName = 'nn';
    return SynchronousFuture<MaterialLocalizations>(
      NnMaterialLocalizations(
        fullYearFormat: intl.DateFormat.y(localeName),
        compactDateFormat: intl.DateFormat.yMd(localeName),
        shortDateFormat: intl.DateFormat.yMMMd(localeName),
        mediumDateFormat: intl.DateFormat.MMMEd(localeName),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(localeName),
        yearMonthFormat: intl.DateFormat.yMMMM(localeName),
        shortMonthDayFormat: intl.DateFormat.MMMd(localeName),
        // `nn` has no number symbols in intl; Norwegian number formatting
        // (comma decimal, non-breaking-space grouping) is identical to `nb`
        // and carries no linguistic content, so we format numbers with `nb`.
        decimalFormat: intl.NumberFormat.decimalPattern('nb'),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'nb'),
      ),
    );
  }

  @override
  bool shouldReload(_NnMaterialLocalizationsDelegate old) => false;
}

class _NnCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _NnCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'nn';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    registerNnLocaleData();
    const localeName = 'nn';
    return SynchronousFuture<CupertinoLocalizations>(
      NnCupertinoLocalizations(
        fullYearFormat: intl.DateFormat.y(localeName),
        dayFormat: intl.DateFormat.d(localeName),
        weekdayFormat: intl.DateFormat.E(localeName),
        mediumDateFormat: intl.DateFormat.MMMEd(localeName),
        singleDigitHourFormat: intl.DateFormat('HH', localeName),
        singleDigitMinuteFormat: intl.DateFormat.m(localeName),
        doubleDigitMinuteFormat: intl.DateFormat('mm', localeName),
        singleDigitSecondFormat: intl.DateFormat.s(localeName),
        decimalFormat: intl.NumberFormat.decimalPattern('nb'),
      ),
    );
  }

  @override
  bool shouldReload(_NnCupertinoLocalizationsDelegate old) => false;
}

/// Nynorsk date/time symbols. Months, eras and quarters match Bokmål; the
/// weekday names carry the Nynorsk-specific forms (måndag/tysdag/laurdag …).
const Map<String, dynamic> _nnDateSymbols = <String, dynamic>{
  'NAME': 'nn',
  'ERAS': <dynamic>['f.Kr.', 'e.Kr.'],
  'ERANAMES': <dynamic>['før Kristus', 'etter Kristus'],
  'NARROWMONTHS': <dynamic>[
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D', //
  ],
  'STANDALONENARROWMONTHS': <dynamic>[
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D', //
  ],
  'MONTHS': <dynamic>[
    'januar',
    'februar',
    'mars',
    'april',
    'mai',
    'juni',
    'juli',
    'august',
    'september',
    'oktober',
    'november',
    'desember',
  ],
  'STANDALONEMONTHS': <dynamic>[
    'januar',
    'februar',
    'mars',
    'april',
    'mai',
    'juni',
    'juli',
    'august',
    'september',
    'oktober',
    'november',
    'desember',
  ],
  'SHORTMONTHS': <dynamic>[
    'jan.',
    'feb.',
    'mars',
    'apr.',
    'mai',
    'juni',
    'juli',
    'aug.',
    'sep.',
    'okt.',
    'nov.',
    'des.',
  ],
  'STANDALONESHORTMONTHS': <dynamic>[
    'jan',
    'feb',
    'mar',
    'apr',
    'mai',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'des',
  ],
  'WEEKDAYS': <dynamic>[
    'søndag',
    'måndag',
    'tysdag',
    'onsdag',
    'torsdag',
    'fredag',
    'laurdag',
  ],
  'STANDALONEWEEKDAYS': <dynamic>[
    'søndag',
    'måndag',
    'tysdag',
    'onsdag',
    'torsdag',
    'fredag',
    'laurdag',
  ],
  'SHORTWEEKDAYS': <dynamic>[
    'søn.',
    'mån.',
    'tys.',
    'ons.',
    'tor.',
    'fre.',
    'laur.',
  ],
  'STANDALONESHORTWEEKDAYS': <dynamic>[
    'søn.',
    'mån.',
    'tys.',
    'ons.',
    'tor.',
    'fre.',
    'laur.',
  ],
  'NARROWWEEKDAYS': <dynamic>['S', 'M', 'T', 'O', 'T', 'F', 'L'],
  'STANDALONENARROWWEEKDAYS': <dynamic>['S', 'M', 'T', 'O', 'T', 'F', 'L'],
  'SHORTQUARTERS': <dynamic>['K1', 'K2', 'K3', 'K4'],
  'QUARTERS': <dynamic>['1. kvartal', '2. kvartal', '3. kvartal', '4. kvartal'],
  'AMPMS': <dynamic>['a.m.', 'p.m.'],
  'DATEFORMATS': <dynamic>[
    'EEEE d. MMMM y',
    'd. MMMM y',
    'd. MMM y',
    'dd.MM.y',
  ],
  'TIMEFORMATS': <dynamic>['HH:mm:ss zzzz', 'HH:mm:ss z', 'HH:mm:ss', 'HH:mm'],
  'AVAILABLEFORMATS': null,
  'FIRSTDAYOFWEEK': 0,
  'WEEKENDRANGE': <dynamic>[5, 6],
  'FIRSTWEEKCUTOFFDAY': 3,
  'DATETIMEFORMATS': <dynamic>['{1}, {0}', '{1}, {0}', '{1}, {0}', '{1}, {0}'],
};

/// Skeleton → pattern map. These are language-neutral formatting skeletons
/// (identical to Bokmål); the localized month/weekday text comes from the
/// symbols above.
const Map<String, String> _nnDatePatterns = <String, String>{
  'd': 'd.',
  'E': 'ccc',
  'EEEE': 'cccc',
  'LLL': 'LLL',
  'LLLL': 'LLLL',
  'M': 'L.',
  'Md': 'd.M.',
  'MEd': 'EEE d.M.',
  'MMM': 'LLL',
  'MMMd': 'd. MMM',
  'MMMEd': 'EEE d. MMM',
  'MMMM': 'LLLL',
  'MMMMd': 'd. MMMM',
  'MMMMEEEEd': 'EEEE d. MMMM',
  'QQQ': 'QQQ',
  'QQQQ': 'QQQQ',
  'y': 'y',
  'yM': 'M.y',
  'yMd': 'd.M.y',
  'yMEd': 'EEE d.M.y',
  'yMMM': 'MMM y',
  'yMMMd': 'd. MMM y',
  'yMMMEd': 'EEE d. MMM y',
  'yMMMM': 'MMMM y',
  'yMMMMd': 'd. MMMM y',
  'yMMMMEEEEd': 'EEEE d. MMMM y',
  'yQQQ': 'QQQ y',
  'yQQQQ': 'QQQQ y',
  'H': 'HH',
  'Hm': 'HH:mm',
  'Hms': 'HH:mm:ss',
  'j': 'HH',
  'jm': 'HH:mm',
  'jms': 'HH:mm:ss',
  'jmv': 'HH:mm v',
  'jmz': 'HH:mm z',
  'jz': 'HH z',
  'm': 'm',
  'ms': 'mm:ss',
  's': 's',
  'v': 'v',
  'z': 'z',
  'zzzz': 'zzzz',
  'ZZZZ': 'ZZZZ',
};

/// Nynorsk Material localizations. Translated from the official Bokmål bundle
/// (`MaterialLocalizationNb`); pending native review.
class NnMaterialLocalizations extends GlobalMaterialLocalizations {
  const NnMaterialLocalizations({
    super.localeName = 'nn',
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  @override
  String get aboutListTileTitleRaw => r'Om $applicationName';

  @override
  String get alertDialogLabel => 'Varsel';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get backButtonTooltip => 'Tilbake';

  @override
  String get bottomSheetLabel => 'Felt nedst';

  @override
  String get calendarModeButtonLabel => 'Byt til kalender';

  @override
  String get cancelButtonLabel => 'Avbryt';

  @override
  String get clearButtonTooltip => 'Slett teksten';

  @override
  String get closeButtonLabel => 'Lukk';

  @override
  String get closeButtonTooltip => 'Lukk';

  @override
  String get collapsedHint => 'Visast';

  @override
  String get collapsedIconTapHint => 'Vis';

  @override
  String get continueButtonLabel => 'Hald fram';

  @override
  String get copyButtonLabel => 'Kopier';

  @override
  String get currentDateLabel => 'I dag';

  @override
  String get cutButtonLabel => 'Klipp ut';

  @override
  String get dateHelpText => 'dd.mm.åååå';

  @override
  String get dateInputLabel => 'Skriv inn datoen';

  @override
  String get dateOutOfRangeLabel => 'Utanfor perioden.';

  @override
  String get datePickerHelpText => 'Vel dato';

  @override
  String get dateRangeEndDateSemanticLabelRaw => r'Sluttdato $fullDate';

  @override
  String get dateRangeEndLabel => 'Sluttdato';

  @override
  String get dateRangePickerHelpText => 'Vel datoperiode';

  @override
  String get dateRangeStartDateSemanticLabelRaw => r'Startdato $fullDate';

  @override
  String get dateRangeStartLabel => 'Startdato';

  @override
  String get dateSeparator => '.';

  @override
  String get deleteButtonTooltip => 'Slett';

  @override
  String get dialModeButtonLabel => 'Byt til modus for val frå urskive';

  @override
  String get dialogLabel => 'Dialogboks';

  @override
  String get drawerLabel => 'Navigasjonsmeny';

  @override
  String get expandedHint => 'Skjulast';

  @override
  String get expandedIconTapHint => 'Skjul';

  @override
  String get expansionTileCollapsedHint => 'dobbelttrykk for å vise';

  @override
  String get expansionTileCollapsedTapHint => 'Vis for å sjå meir informasjon';

  @override
  String get expansionTileExpandedHint => 'dobbelttrykk for å skjule';

  @override
  String get expansionTileExpandedTapHint => 'Skjul';

  @override
  String get firstPageTooltip => 'Første side';

  @override
  String get hideAccountsLabel => 'Skjul kontoar';

  @override
  String get inputDateModeButtonLabel => 'Byt til innskriving';

  @override
  String get inputTimeModeButtonLabel => 'Byt til tekstinndatamodus';

  @override
  String get invalidDateFormatLabel => 'Ugyldig format.';

  @override
  String get invalidDateRangeLabel => 'Ugyldig periode.';

  @override
  String get invalidTimeLabel => 'Oppgi eit gyldig klokkeslett';

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'Alt Gr';

  @override
  String get keyboardKeyBackspace => 'Tilbaketast';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyChannelDown => 'Førre kanal';

  @override
  String get keyboardKeyChannelUp => 'Neste kanal';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEject => 'Løys ut';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyFn => 'Fn';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaMacOs => 'Kommando';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyNumpad0 => 'Num 0';

  @override
  String get keyboardKeyNumpad1 => 'Num 1';

  @override
  String get keyboardKeyNumpad2 => 'Num 2';

  @override
  String get keyboardKeyNumpad3 => 'Num 3';

  @override
  String get keyboardKeyNumpad4 => 'Num 4';

  @override
  String get keyboardKeyNumpad5 => 'Num 5';

  @override
  String get keyboardKeyNumpad6 => 'Num 6';

  @override
  String get keyboardKeyNumpad7 => 'Num 7';

  @override
  String get keyboardKeyNumpad8 => 'Num 8';

  @override
  String get keyboardKeyNumpad9 => 'Num 9';

  @override
  String get keyboardKeyNumpadAdd => 'Num +';

  @override
  String get keyboardKeyNumpadComma => 'Num ,';

  @override
  String get keyboardKeyNumpadDecimal => 'Num .';

  @override
  String get keyboardKeyNumpadDivide => 'Num /';

  @override
  String get keyboardKeyNumpadEnter => 'Num Enter';

  @override
  String get keyboardKeyNumpadEqual => 'Num =';

  @override
  String get keyboardKeyNumpadMultiply => 'Num *';

  @override
  String get keyboardKeyNumpadParenLeft => 'Num (';

  @override
  String get keyboardKeyNumpadParenRight => 'Num )';

  @override
  String get keyboardKeyNumpadSubtract => 'Num -';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeyPower => 'Av/på';

  @override
  String get keyboardKeyPowerOff => 'Slå av';

  @override
  String get keyboardKeyPrintScreen => 'PrtScn';

  @override
  String get keyboardKeyScrollLock => 'ScrLk';

  @override
  String get keyboardKeySelect => 'Vel';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeySpace => 'Mellomrom';

  @override
  String get lastPageTooltip => 'Siste side';

  @override
  String? get licensesPackageDetailTextFew => null;

  @override
  String? get licensesPackageDetailTextMany => null;

  @override
  String? get licensesPackageDetailTextOne => '1 lisens';

  @override
  String get licensesPackageDetailTextOther => r'$licenseCount lisensar';

  @override
  String? get licensesPackageDetailTextTwo => null;

  @override
  String? get licensesPackageDetailTextZero => null;

  @override
  String get licensesPageTitle => 'Lisensar';

  @override
  String get lookUpButtonLabel => 'Slå opp';

  @override
  String get menuBarMenuLabel => 'Meny med menylinje';

  @override
  String get menuDismissLabel => 'Lukk menyen';

  @override
  String get modalBarrierDismissLabel => 'Avvis';

  @override
  String get moreButtonTooltip => 'Meir';

  @override
  String get nextMonthTooltip => 'Neste månad';

  @override
  String get nextPageTooltip => 'Neste side';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get openAppDrawerTooltip => 'Opne navigasjonsmenyen';

  @override
  String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow av $rowCount';

  @override
  String get pageRowsInfoTitleApproximateRaw =>
      r'$firstRow–$lastRow av om lag $rowCount';

  @override
  String get pasteButtonLabel => 'Lim inn';

  @override
  String get popupMenuLabel => 'Forgrunnsmeny';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get previousMonthTooltip => 'Førre månad';

  @override
  String get previousPageTooltip => 'Førre side';

  @override
  String get refreshIndicatorSemanticLabel => 'Lastar inn på nytt';

  @override
  String? get remainingTextFieldCharacterCountFew => null;

  @override
  String? get remainingTextFieldCharacterCountMany => null;

  @override
  String? get remainingTextFieldCharacterCountOne => '1 teikn står att';

  @override
  String get remainingTextFieldCharacterCountOther =>
      r'$remainingCount teikn står att';

  @override
  String? get remainingTextFieldCharacterCountTwo => null;

  @override
  String? get remainingTextFieldCharacterCountZero => null;

  @override
  String get reorderItemDown => 'Flytt ned';

  @override
  String get reorderItemLeft => 'Flytt til venstre';

  @override
  String get reorderItemRight => 'Flytt til høgre';

  @override
  String get reorderItemToEnd => 'Flytt til slutten';

  @override
  String get reorderItemToStart => 'Flytt til starten';

  @override
  String get reorderItemUp => 'Flytt opp';

  @override
  String get rowsPerPageTitle => 'Rader per side:';

  @override
  String get saveButtonLabel => 'Lagre';

  @override
  String get scanTextButtonLabel => 'Skann tekst';

  @override
  String get scrimLabel => 'Vev';

  @override
  String get scrimOnTapHintRaw => r'Lukk $modalRouteContentName';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  @override
  String get searchFieldLabel => 'Søk';

  @override
  String get searchWebButtonLabel => 'Søk på nettet';

  @override
  String get selectAllButtonLabel => 'Vel alle';

  @override
  String get selectYearSemanticsLabel => 'Vel året';

  @override
  String get selectedDateLabel => 'Vald';

  @override
  String? get selectedRowCountTitleFew => null;

  @override
  String? get selectedRowCountTitleMany => null;

  @override
  String? get selectedRowCountTitleOne => '1 element er valt';

  @override
  String get selectedRowCountTitleOther =>
      r'$selectedRowCount element er valde';

  @override
  String? get selectedRowCountTitleTwo => null;

  @override
  String? get selectedRowCountTitleZero => null;

  @override
  String get shareButtonLabel => 'Del';

  @override
  String get showAccountsLabel => 'Vis kontoar';

  @override
  String get showMenuTooltip => 'Vis meny';

  @override
  String get signedInLabel => 'Pålogga';

  @override
  String get tabLabelRaw => r'Fane $tabIndex av $tabCount';

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.HH_colon_mm;

  @override
  String get timePickerDialHelpText => 'Vel tidspunkt';

  @override
  String get timePickerHourLabel => 'Time';

  @override
  String get timePickerHourModeAnnouncement => 'Oppgi timar';

  @override
  String get timePickerInputHelpText => 'Oppgi eit tidspunkt';

  @override
  String get timePickerMinuteLabel => 'Minutt';

  @override
  String get timePickerMinuteModeAnnouncement => 'Oppgi minutt';

  @override
  String get unspecifiedDate => 'Dato';

  @override
  String get unspecifiedDateRange => 'Datoperiode';

  @override
  String get viewLicensesButtonLabel => 'Sjå lisensar';
}

/// Nynorsk Cupertino localizations. Translated from the official Bokmål bundle
/// (`CupertinoLocalizationNb`); pending native review.
class NnCupertinoLocalizations extends GlobalCupertinoLocalizations {
  const NnCupertinoLocalizations({
    super.localeName = 'nn',
    required super.fullYearFormat,
    required super.dayFormat,
    required super.weekdayFormat,
    required super.mediumDateFormat,
    required super.singleDigitHourFormat,
    required super.singleDigitMinuteFormat,
    required super.doubleDigitMinuteFormat,
    required super.singleDigitSecondFormat,
    required super.decimalFormat,
  });

  @override
  String get alertDialogLabel => 'Varsel';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get backButtonLabel => 'Tilbake';

  @override
  String get cancelButtonLabel => 'Avbryt';

  @override
  String get clearButtonLabel => 'Slett';

  @override
  String get collapsedHint => 'Visast';

  @override
  String get copyButtonLabel => 'Kopier';

  @override
  String get cutButtonLabel => 'Klipp ut';

  @override
  String get datePickerDateOrderString => 'dmy';

  @override
  String get datePickerDateTimeOrderString => 'date_time_dayPeriod';

  @override
  String? get datePickerHourSemanticsLabelFew => null;

  @override
  String? get datePickerHourSemanticsLabelMany => null;

  @override
  String? get datePickerHourSemanticsLabelOne => r'$hour null-null';

  @override
  String get datePickerHourSemanticsLabelOther => r'$hour null-null';

  @override
  String? get datePickerHourSemanticsLabelTwo => null;

  @override
  String? get datePickerHourSemanticsLabelZero => null;

  @override
  String? get datePickerMinuteSemanticsLabelFew => null;

  @override
  String? get datePickerMinuteSemanticsLabelMany => null;

  @override
  String? get datePickerMinuteSemanticsLabelOne => '1 minutt';

  @override
  String get datePickerMinuteSemanticsLabelOther => r'$minute minutt';

  @override
  String? get datePickerMinuteSemanticsLabelTwo => null;

  @override
  String? get datePickerMinuteSemanticsLabelZero => null;

  @override
  String get expandedHint => 'Skjulast';

  @override
  String get expansionTileCollapsedHint => 'dobbelttrykk for å vise';

  @override
  String get expansionTileCollapsedTapHint => 'Vis for å sjå meir informasjon';

  @override
  String get expansionTileExpandedHint => 'dobbelttrykk for å skjule';

  @override
  String get expansionTileExpandedTapHint => 'Skjul';

  @override
  String get lookUpButtonLabel => 'Slå opp';

  @override
  String get menuDismissLabel => 'Lukk menyen';

  @override
  String get modalBarrierDismissLabel => 'Avvis';

  @override
  String get noSpellCheckReplacementsLabel => 'Fann ingen erstatningar';

  @override
  String get pasteButtonLabel => 'Lim inn';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get searchTextFieldPlaceholderLabel => 'Søk';

  @override
  String get searchWebButtonLabel => 'Søk på nettet';

  @override
  String get selectAllButtonLabel => 'Vel alle';

  @override
  String get shareButtonLabel => 'Del…';

  @override
  String get tabSemanticsLabelRaw => r'Fane $tabIndex av $tabCount';

  @override
  String? get timerPickerHourLabelFew => null;

  @override
  String? get timerPickerHourLabelMany => null;

  @override
  String? get timerPickerHourLabelOne => 'time';

  @override
  String get timerPickerHourLabelOther => 'timar';

  @override
  String? get timerPickerHourLabelTwo => null;

  @override
  String? get timerPickerHourLabelZero => null;

  @override
  String? get timerPickerMinuteLabelFew => null;

  @override
  String? get timerPickerMinuteLabelMany => null;

  @override
  String? get timerPickerMinuteLabelOne => 'min.';

  @override
  String get timerPickerMinuteLabelOther => 'min.';

  @override
  String? get timerPickerMinuteLabelTwo => null;

  @override
  String? get timerPickerMinuteLabelZero => null;

  @override
  String? get timerPickerSecondLabelFew => null;

  @override
  String? get timerPickerSecondLabelMany => null;

  @override
  String? get timerPickerSecondLabelOne => 'sek.';

  @override
  String get timerPickerSecondLabelOther => 'sek.';

  @override
  String? get timerPickerSecondLabelTwo => null;

  @override
  String? get timerPickerSecondLabelZero => null;

  @override
  String get todayLabel => 'I dag';
}
