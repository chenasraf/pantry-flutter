import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry_core/services/api_client.dart';

/// A resolved product for a barcode (EAN/UPC). Mirrors the server's
/// `PantryBarcode` shape — the shared cache and the Open Food Facts resolve
/// path both produce one of these.
class BarcodeResult {
  final String ean;
  final String name;
  final String provider;
  final String? brand;
  final String? category;
  final String? imageUrl;

  const BarcodeResult({
    required this.ean,
    required this.name,
    required this.provider,
    this.brand,
    this.category,
    this.imageUrl,
  });

  factory BarcodeResult.fromJson(Map<String, dynamic> json) => BarcodeResult(
    ean: json['ean'] as String,
    name: json['name'] as String,
    provider: json['provider'] as String? ?? 'openfoodfacts',
    brand: json['brand'] as String?,
    category: json['category'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'ean': ean,
    'name': name,
    'provider': provider,
    'brand': ?brand,
    'category': ?category,
    'imageUrl': ?imageUrl,
  };
}

/// Barcode lookup pipeline. A scan is never an API call — only a *cache miss*
/// is. The shared server-side cache is checked first ([lookup]); on a miss the
/// client resolves the product from its own IP against Open Food Facts
/// ([resolveExternally]) and writes the result back ([save]) so the whole
/// house gets it for free next time.
class BarcodeService {
  BarcodeService._();
  static final BarcodeService instance = BarcodeService._();

  /// Open Food Facts read API base. Called directly (not through [ApiClient],
  /// which is scoped to the Nextcloud instance) — mobile has no CORS problem.
  static const _offBase = 'https://world.openfoodfacts.org/api/v2/product';

  static const _timeout = Duration(seconds: 10);

  /// Descriptive User-Agent — Open Food Facts requires one and throttles
  /// anonymous/blank agents harder.
  String get _userAgent => 'Pantry/$appVersion (contact@casraf.dev)';

  /// Whether [ean] is a plausible barcode. The server accepts 6–14 digits.
  static bool isValidEan(String ean) =>
      RegExp(r'^\d{6,14}$').hasMatch(ean.trim());

  /// `GET /barcode/{ean}` — cache-only lookup, never makes an external call.
  /// Returns null on a cache miss (404); rethrows any other error.
  Future<BarcodeResult?> lookup(String ean) async {
    try {
      return await ApiClient.instance.get<Map<String, dynamic>, BarcodeResult>(
        '/barcode/$ean',
        fromJson: (data) => BarcodeResult.fromJson(data),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// `POST /barcode` — write a client-resolved result back to the shared
  /// cache. Best-effort: swallow errors at the call site.
  Future<BarcodeResult> save(BarcodeResult r) async {
    return ApiClient.instance.post<Map<String, dynamic>, BarcodeResult>(
      '/barcode',
      body: r.toJson(),
      fromJson: (data) => BarcodeResult.fromJson(data),
    );
  }

  /// Resolve [ean] from the device's own IP against Open Food Facts. Returns
  /// null when the product is unknown or on any network error — never throws
  /// for "not found", so a rate limit only ever delays enrichment.
  Future<BarcodeResult?> resolveExternally(String ean) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_offBase/$ean.json'),
            headers: {'User-Agent': _userAgent},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;
      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final name = _firstNonEmpty([
        product['product_name'],
        product['generic_name'],
        product['abbreviated_product_name'],
      ]);
      if (name == null) return null;

      return BarcodeResult(
        ean: ean,
        name: name,
        provider: 'openfoodfacts',
        brand: _firstCsv(product['brands']),
        category: _firstCsv(product['categories']),
        imageUrl: _firstNonEmpty([product['image_url']]),
      );
    } catch (_) {
      // Network error, timeout, malformed JSON — treat as "unknown" so the
      // UI falls back to the raw EAN rather than erroring.
      return null;
    }
  }

  /// Download the product image bytes for a resolved result, best-effort.
  /// Returns null on any error so a missing/broken image just skips the
  /// attach step rather than failing the whole add.
  Future<List<int>?> downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  /// First non-blank string in [values], trimmed; null if none.
  static String? _firstNonEmpty(List<Object?> values) {
    for (final v in values) {
      if (v is String) {
        final trimmed = v.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }

  /// Open Food Facts joins brands/categories as a comma-separated string;
  /// keep the first entry.
  static String? _firstCsv(Object? value) {
    if (value is! String) return null;
    final first = value.split(',').first.trim();
    return first.isEmpty ? null : first;
  }
}
