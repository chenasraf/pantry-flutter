/// What a typed item line splits into: the item's name and, when the line
/// carried one, its quantity ("2 L milk" → "milk", "2 L").
class ItemInput {
  final String name;
  final String? quantity;

  const ItemInput(this.name, [this.quantity]);

  @override
  bool operator ==(Object other) =>
      other is ItemInput && other.name == name && other.quantity == quantity;

  @override
  int get hashCode => Object.hash(name, quantity);

  @override
  String toString() => 'ItemInput($name, $quantity)';
}

/// Metric and imperial symbols, read in every language.
final _symbolUnits = _words('mg kg ml cl dl oz lb lbs cm mm pc pcs');

/// Single letters are units only in these exact spellings, so a glued brand
/// like "3M" stays a name while "500g" and "2L" split.
const _letterUnits = {'g', 'l', 'L', 'm'};

/// Word units per language, lowercase. English is read in every language too,
/// since a household's lists rarely stick to one.
final _wordUnits = <String, Set<String>>{
  'en': _words(
    'gram grams kilo kilos kilogram kilograms liter liters litre litres '
    'milliliter milliliters millilitre millilitres ounce ounces pound pounds '
    'cup cups tbsp tsp pack packs packet packets can cans bottle bottles box '
    'boxes bag bags jar jars dozen piece pieces loaf loaves bunch bunches '
    'carton cartons tub tubs roll rolls',
  ),
  'de': _words(
    'gramm kilo kilogramm liter milliliter stück stk packung packungen pkg '
    'pck dose dosen flasche flaschen glas gläser beutel becher bund tüte '
    'tüten el tl tasse tassen kiste kisten rolle rollen schachtel schachteln',
  ),
  'es': _words(
    'gramo gramos kilo kilos kilogramo kilogramos litro litros mililitro '
    'mililitros paquete paquetes lata latas botella botellas caja cajas bolsa '
    'bolsas docena docenas unidad unidades pieza piezas bote botes tarro '
    'tarros taza tazas rollo rollos',
  ),
  'fr': _words(
    'gramme grammes kilo kilos kilogramme kilogrammes litre litres millilitre '
    'millilitres paquet paquets boîte boîtes boite boites bouteille '
    'bouteilles sachet sachets pot pots douzaine douzaines pièce pièces '
    'tranche tranches canette canettes brique briques tasse tasses rouleau '
    'rouleaux',
  ),
  'nn': _words(
    'gram kilo liter desiliter stk stykke stykkje pakke pakkar pakker boks '
    'boksar bokser flaske flasker pose posar poser glas bunt kartong '
    'kartongar kartonger rull rullar ruller',
  ),
  'he': _words(
    'גרם ג\' ג׳ קילו ק"ג ק״ג קג ליטר ל\' ל׳ מ"ל מ״ל מל יחידה יחידות יח\' '
    'יח׳ חבילה חבילות בקבוק בקבוקים קופסה קופסאות שקית שקיות פחית פחיות '
    'תריסר מגש מגשים צנצנת צנצנות כוס כוסות',
  ),
};

Set<String> _words(String words) => words.split(' ').toSet();

/// Words that may sit between a unit and the name ("2 kg of flour").
const _connectors = <String, List<String>>{
  'en': ['of'],
  'es': ['de'],
  'fr': ['de', "d'", 'd’'],
};

/// Languages that write a decimal comma ("1,5 kg"). The decimal point is read
/// in every language.
const _decimalComma = {'de', 'es', 'fr', 'nn'};

const _fractions = '½⅓⅔¼¾⅕⅛';

final _listMarkup = RegExp(
  r'^\s*(?:(?:[-*+•]\s+)?\[[ xX]\]\s+|[-*+•]\s+|\d+[.)]\s+)',
);
final _hasLetter = RegExp(r'\p{L}', unicode: true);

/// Splits [text] into a name and a quantity, reading units the way people in
/// [locale] write them. A line with nothing that reads as a quantity comes
/// back whole as the name.
///
/// Quantities lead ("2 L milk", "2x eggs", "x3 limes") or trail ("milk 2 L",
/// "eggs x2", "eggs 2x"). A number glued to letters splits only when the
/// letters are a unit, so "7up" and "3M tape" stay names. List markup
/// ("- ", "* ", "1. ", "- [ ] ") is dropped first.
ItemInput parseItemInput(String text, String locale) {
  final line = text.replaceFirst(_listMarkup, '').trim();
  if (line.isEmpty) return const ItemInput('');
  return _ItemInputParser.forLocale(locale).parse(line);
}

class _ItemInputParser {
  final Set<String> units;
  final List<String> connectors;
  final RegExp leadingTimes;
  final RegExp leadingTimesBefore;
  final RegExp leadingUnit;
  final RegExp leadingBare;
  final RegExp trailingTimes;
  final RegExp trailingTimesAfter;
  final RegExp trailingUnit;

  _ItemInputParser._(this.units, this.connectors, String number)
    : leadingTimes = _re('^($number)\\s*[xX×]\\s+(.+)\$'),
      leadingTimesBefore = _re('^[xX×]\\s*($number)\\s+(.+)\$'),
      leadingUnit = _re('^($number)\\s*($_unitToken)\\s+(.+)\$'),
      leadingBare = _re('^($number)\\s+(.+)\$'),
      trailingTimes = _re('^(.+?)\\s+[xX×]\\s*($number)\$'),
      trailingTimesAfter = _re('^(.+?)\\s+($number)\\s*[xX×]\$'),
      trailingUnit = _re('^(.+?)\\s+($number)\\s*($_unitToken)\$');

  static const _unitToken = '\\p{L}[\\p{L}.\'"׳״]*';

  static RegExp _re(String source) => RegExp(source, unicode: true);

  static final _cache = <String, _ItemInputParser>{};

  factory _ItemInputParser.forLocale(String locale) {
    final lang = locale.split(RegExp('[-_]')).first.toLowerCase();
    return _cache.putIfAbsent(lang, () {
      final decimal = _decimalComma.contains(lang) ? '[.,]' : '\\.';
      final number = '\\d+/\\d+|\\d*[$_fractions]|\\d+(?:$decimal\\d+)?';
      return _ItemInputParser._(
        {..._wordUnits['en']!, ...?_wordUnits[lang]},
        [...?_connectors['en'], if (lang != 'en') ...?_connectors[lang]],
        number,
      );
    });
  }

  bool _isUnit(String token) {
    final unit = token.endsWith('.')
        ? token.substring(0, token.length - 1)
        : token;
    if (unit.length == 1) return _letterUnits.contains(unit);
    final lower = unit.toLowerCase();
    return _symbolUnits.contains(lower) || units.contains(lower);
  }

  String _dropConnector(String rest) {
    final lower = rest.toLowerCase();
    for (final c in connectors) {
      final glued = c.endsWith("'") || c.endsWith('’');
      if (glued && lower.startsWith(c) && rest.length > c.length) {
        return rest.substring(c.length).trimLeft();
      }
      if (!glued && lower.startsWith('$c ')) {
        return rest.substring(c.length).trimLeft();
      }
    }
    return rest;
  }

  ItemInput parse(String line) {
    ItemInput? named(String name, String quantity) {
      final trimmed = name.trim();
      if (!_hasLetter.hasMatch(trimmed)) return null;
      // A quantity with nothing after it but a unit names no item ("2 L").
      if (!trimmed.contains(' ') && _isUnit(trimmed)) return null;
      return ItemInput(trimmed, quantity);
    }

    ItemInput? first(List<ItemInput? Function()> forms) {
      for (final form in forms) {
        final result = form();
        if (result != null) return result;
      }
      return null;
    }

    return first([
          () {
            final m = leadingTimes.firstMatch(line);
            return m == null ? null : named(m[2]!, m[1]!);
          },
          () {
            final m = leadingTimesBefore.firstMatch(line);
            return m == null ? null : named(m[2]!, m[1]!);
          },
          () {
            final m = leadingUnit.firstMatch(line);
            if (m == null || !_isUnit(m[2]!)) return null;
            return named(_dropConnector(m[3]!), '${m[1]} ${m[2]}');
          },
          () {
            final m = leadingBare.firstMatch(line);
            return m == null ? null : named(m[2]!, m[1]!);
          },
          () {
            final m = trailingTimes.firstMatch(line);
            return m == null ? null : named(m[1]!, m[2]!);
          },
          () {
            final m = trailingTimesAfter.firstMatch(line);
            return m == null ? null : named(m[1]!, m[2]!);
          },
          () {
            final m = trailingUnit.firstMatch(line);
            if (m == null || !_isUnit(m[3]!)) return null;
            return named(m[1]!, '${m[2]} ${m[3]}');
          },
        ]) ??
        ItemInput(line);
  }
}
