import 'package:flutter/material.dart';

import 'package:pantry_core/utils/platform_info.dart';

Widget? appBarBackLeading(BuildContext context) {
  if (!PlatformInfo.isMacOS) return null;
  final route = ModalRoute.of(context);
  if (route?.canPop != true) return null;
  return const Align(
    alignment: AlignmentDirectional.bottomCenter,
    child: BackButton(),
  );
}
