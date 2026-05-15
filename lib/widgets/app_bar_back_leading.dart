import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

Widget? appBarBackLeading(BuildContext context) {
  if (kIsWeb || !Platform.isMacOS) return null;
  final route = ModalRoute.of(context);
  if (route?.canPop != true) return null;
  return const Align(
    alignment: AlignmentDirectional.bottomCenter,
    child: BackButton(),
  );
}
