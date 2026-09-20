import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/server_url.dart';

/// Why a control that needs the server is blocked, or null while it can be
/// reached.
///
/// Two different truths hide behind one dead request, and a wearer can only act
/// on one of them. A watch linked over Bluetooth is handed the phone's
/// *internet*, not the phone's *network* — so a server on the household's own
/// network is out of reach across a link that is working perfectly, and telling
/// that wearer they need a connection describes their watch to them wrongly.
/// What they need is this watch on Wi-Fi.
///
/// [isPrivateHost] is only trusted in the direction it is reliable: a yes names
/// the reason, and a no falls back to the general answer rather than promising
/// that the server was reachable.
String? unreachableReason(bool isOnline) {
  if (isOnline) return null;
  final url = AuthService.instance.credentials?.serverUrl;
  final host = url == null ? null : Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return m.wear.needsConnection;
  return isPrivateHost(host) ? m.wear.needsWifi : m.wear.needsConnection;
}
