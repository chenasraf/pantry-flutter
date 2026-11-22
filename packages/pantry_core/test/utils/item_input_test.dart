import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/item_input.dart';

void main() {
  /// (locale, typed, name, quantity)
  const cases = <(String, String, String, String?)>[
    // Leading quantities
    ('en', '2 L milk', 'milk', '2 L'),
    ('en', '2L milk', 'milk', '2 L'),
    ('en', '500g flour', 'flour', '500 g'),
    ('en', '1.5 kg rice', 'rice', '1.5 kg'),
    ('en', '2 eggs', 'eggs', '2'),
    ('en', '2 large eggs', 'large eggs', '2'),
    ('en', '2x lemons', 'lemons', '2'),
    ('en', '2 x lemons', 'lemons', '2'),
    ('en', '2× lemons', 'lemons', '2'),
    ('en', 'x3 limes', 'limes', '3'),
    ('en', '3 cans tomatoes', 'tomatoes', '3 cans'),
    ('en', '2 kg of flour', 'flour', '2 kg'),
    ('en', '1/2 kg butter', 'butter', '1/2 kg'),
    ('en', '½ lb ham', 'ham', '½ lb'),
    ('en', '1½ cups sugar', 'sugar', '1½ cups'),

    // Trailing quantities
    ('en', 'milk 2 L', 'milk', '2 L'),
    ('en', 'flour 500g', 'flour', '500 g'),
    ('en', 'eggs x2', 'eggs', '2'),
    ('en', 'eggs x 2', 'eggs', '2'),
    ('en', 'eggs 2x', 'eggs', '2'),

    // Names that only look like quantities
    ('en', '7up', '7up', null),
    ('en', '7up 2x', '7up', '2'),
    ('en', '3M tape', '3M tape', null),
    ('en', 'Milk', 'Milk', null),
    ('en', 'milk 2', 'milk 2', null),
    ('en', '2 L', '2 L', null),
    ('en', '2x', '2x', null),
    ('en', '100% juice', '100% juice', null),
    ('en', '2 xl shirts', 'xl shirts', '2'),
    ('en', 'Vitamin B12', 'Vitamin B12', null),

    // Decimal comma only where the language writes one
    ('en', '1,5 kg rice', '1,5 kg rice', null),
    ('de', '1,5 kg Reis', 'Reis', '1,5 kg'),
    ('de', '1.5 kg Reis', 'Reis', '1.5 kg'),
    ('fr', '0,5 L lait', 'lait', '0,5 L'),

    // Units per language
    ('de', '2 Stück Butter', 'Butter', '2 Stück'),
    ('de', '2 Stk. Butter', 'Butter', '2 Stk.'),
    ('de', '3 Flaschen Wasser', 'Wasser', '3 Flaschen'),
    ('es', '1 kg de harina', 'harina', '1 kg'),
    ('es', '2 latas atún', 'atún', '2 latas'),
    ('fr', "500 g d'huile", 'huile', '500 g'),
    ('fr', '2 bouteilles de vin', 'vin', '2 bouteilles'),
    ('nn', '2 pakkar smør', 'smør', '2 pakkar'),
    ('he', '2 ליטר חלב', 'חלב', '2 ליטר'),
    ('he', 'חלב 2 ליטר', 'חלב', '2 ליטר'),
    ('he', '1 ק״ג קמח', 'קמח', '1 ק״ג'),
    ('he', '3 ביצים', 'ביצים', '3'),
    ('he', 'חלב', 'חלב', null),
    ('en-US', '2 L milk', 'milk', '2 L'),
    ('de_AT', '1,5 kg Reis', 'Reis', '1,5 kg'),
    // English units are read in every language.
    ('he', '2 packs פיתות', 'פיתות', '2 packs'),

    // List markup
    ('en', '- 2 L milk', 'milk', '2 L'),
    ('en', '* bread', 'bread', null),
    ('en', '1. eggs', 'eggs', null),
    ('en', '2) eggs', 'eggs', null),
    ('en', '- [ ] butter', 'butter', null),
    ('en', '- [x] 2 x butter', 'butter', '2'),
    ('en', '[ ] butter', 'butter', null),
    ('en', '  bread  ', 'bread', null),
    ('en', '', '', null),
  ];

  for (final (locale, typed, name, quantity) in cases) {
    test('$locale: "$typed"', () {
      expect(parseItemInput(typed, locale), ItemInput(name, quantity));
    });
  }
}
