import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pantry_core/services/locale_service.dart';

/// The phone app's localizations delegates: the shared framework set plus the
/// WYSIWYG markdown editor's own bundle.
const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  ...baseLocalizationsDelegates,
  FlutterQuillLocalizations.delegate,
];
