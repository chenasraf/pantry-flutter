/// Curated list of common currencies with an explicit symbol and placement,
/// ported from the Pantry web app (`src/utils/currencies.ts`).
///
/// Placement is intentionally hand-set (not locale-derived) so a price reads
/// the same for everyone: USD before the amount ($1), ILS after (1₪). Exposed
/// [currencies] is sorted by name; [defaultCurrency] (USD) is the app-wide
/// default.
library;

class Currency {
  /// ISO 4217 code, e.g. 'USD'.
  final String code;

  /// Full English name, e.g. 'United States Dollar'.
  final String name;

  /// Display symbol, e.g. '$' or '₪'.
  final String symbol;

  /// Whether the symbol sits before the amount (`$1`) or after (`1₪`).
  final bool symbolBefore;

  /// Number of fractional digits the currency conventionally uses.
  final int decimals;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.symbolBefore,
    required this.decimals,
  });
}

const String defaultCurrency = 'USD';

const List<Currency> _unsorted = [
  Currency(
    code: 'ARS',
    name: 'Argentine Peso',
    symbol: '\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: 'A\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'BHD',
    name: 'Bahraini Dinar',
    symbol: 'BD',
    symbolBefore: true,
    decimals: 3,
  ),
  Currency(
    code: 'BDT',
    name: 'Bangladeshi Taka',
    symbol: '৳',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'BRL',
    name: 'Brazilian Real',
    symbol: 'R\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'BGN',
    name: 'Bulgarian Lev',
    symbol: 'лв',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: 'C\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'CLP',
    name: 'Chilean Peso',
    symbol: '\$',
    symbolBefore: true,
    decimals: 0,
  ),
  Currency(
    code: 'CNY',
    name: 'Chinese Yuan',
    symbol: '¥',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'COP',
    name: 'Colombian Peso',
    symbol: '\$',
    symbolBefore: true,
    decimals: 0,
  ),
  Currency(
    code: 'CRC',
    name: 'Costa Rican Colón',
    symbol: '₡',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'CZK',
    name: 'Czech Koruna',
    symbol: 'Kč',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'DKK',
    name: 'Danish Krone',
    symbol: 'kr',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'DOP',
    name: 'Dominican Peso',
    symbol: 'RD\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'EGP',
    name: 'Egyptian Pound',
    symbol: 'E£',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'GHS',
    name: 'Ghanaian Cedi',
    symbol: '₵',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'GTQ',
    name: 'Guatemalan Quetzal',
    symbol: 'Q',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'HKD',
    name: 'Hong Kong Dollar',
    symbol: 'HK\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'HUF',
    name: 'Hungarian Forint',
    symbol: 'Ft',
    symbolBefore: false,
    decimals: 0,
  ),
  Currency(
    code: 'ISK',
    name: 'Icelandic Króna',
    symbol: 'kr',
    symbolBefore: false,
    decimals: 0,
  ),
  Currency(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'IDR',
    name: 'Indonesian Rupiah',
    symbol: 'Rp',
    symbolBefore: true,
    decimals: 0,
  ),
  Currency(
    code: 'ILS',
    name: 'Israeli New Shekel',
    symbol: '₪',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    symbolBefore: true,
    decimals: 0,
  ),
  Currency(
    code: 'JOD',
    name: 'Jordanian Dinar',
    symbol: 'JD',
    symbolBefore: true,
    decimals: 3,
  ),
  Currency(
    code: 'KES',
    name: 'Kenyan Shilling',
    symbol: 'KSh',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'KWD',
    name: 'Kuwaiti Dinar',
    symbol: 'KD',
    symbolBefore: true,
    decimals: 3,
  ),
  Currency(
    code: 'MYR',
    name: 'Malaysian Ringgit',
    symbol: 'RM',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'MXN',
    name: 'Mexican Peso',
    symbol: '\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'MAD',
    name: 'Moroccan Dirham',
    symbol: 'MAD',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'TWD',
    name: 'New Taiwan Dollar',
    symbol: 'NT\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'NZD',
    name: 'New Zealand Dollar',
    symbol: 'NZ\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'NGN',
    name: 'Nigerian Naira',
    symbol: '₦',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'NOK',
    name: 'Norwegian Krone',
    symbol: 'kr',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'OMR',
    name: 'Omani Rial',
    symbol: '﷼',
    symbolBefore: true,
    decimals: 3,
  ),
  Currency(
    code: 'PKR',
    name: 'Pakistani Rupee',
    symbol: '₨',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'PEN',
    name: 'Peruvian Sol',
    symbol: 'S/',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'PHP',
    name: 'Philippine Peso',
    symbol: '₱',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'PLN',
    name: 'Polish Złoty',
    symbol: 'zł',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'GBP',
    name: 'Pound Sterling',
    symbol: '£',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'QAR',
    name: 'Qatari Riyal',
    symbol: 'QAR',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'RON',
    name: 'Romanian Leu',
    symbol: 'lei',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'RUB',
    name: 'Russian Ruble',
    symbol: '₽',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'SAR',
    name: 'Saudi Riyal',
    symbol: 'SAR',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'RSD',
    name: 'Serbian Dinar',
    symbol: 'дин',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: 'S\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'ZAR',
    name: 'South African Rand',
    symbol: 'R',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'KRW',
    name: 'South Korean Won',
    symbol: '₩',
    symbolBefore: true,
    decimals: 0,
  ),
  Currency(
    code: 'LKR',
    name: 'Sri Lankan Rupee',
    symbol: '₨',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'SEK',
    name: 'Swedish Krona',
    symbol: 'kr',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'CHF',
    name: 'Swiss Franc',
    symbol: 'CHF',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'THB',
    name: 'Thai Baht',
    symbol: '฿',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'TRY',
    name: 'Turkish Lira',
    symbol: '₺',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'AED',
    name: 'UAE Dirham',
    symbol: 'AED',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'UAH',
    name: 'Ukrainian Hryvnia',
    symbol: '₴',
    symbolBefore: false,
    decimals: 2,
  ),
  Currency(
    code: 'USD',
    name: 'United States Dollar',
    symbol: '\$',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'UYU',
    name: 'Uruguayan Peso',
    symbol: '\$U',
    symbolBefore: true,
    decimals: 2,
  ),
  Currency(
    code: 'VND',
    name: 'Vietnamese Dong',
    symbol: '₫',
    symbolBefore: false,
    decimals: 0,
  ),
];

/// All currencies, sorted by [Currency.name]. Backs the currency dropdown.
final List<Currency> currencies = [..._unsorted]
  ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

final Map<String, Currency> _byCode = {for (final c in _unsorted) c.code: c};

/// Look up a known currency by code (case-insensitive), or null if unknown.
Currency? currencyByCode(String? code) {
  if (code == null || code.isEmpty) return null;
  return _byCode[code.toUpperCase()];
}

/// Resolve a currency to its definition, falling back to a synthetic entry that
/// shows the raw code before the amount. Keeps unknown codes displayable.
Currency resolveCurrency(String? code) {
  final known = currencyByCode(code);
  if (known != null) return known;
  final upper = (code == null || code.isEmpty ? defaultCurrency : code)
      .toUpperCase();
  return Currency(
    code: upper,
    name: upper,
    symbol: upper,
    symbolBefore: true,
    decimals: 2,
  );
}
