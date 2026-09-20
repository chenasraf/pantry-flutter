/// What a typed server address means, for every surface that accepts one.
///
/// Two sign-in paths now take an address from a human — the phone's login
/// screen and the watch's QR path — and a host they disagree about is a
/// pinned certificate one of them cannot match.
String normalizeServerUrl(String raw) {
  var url = raw.trim();
  if (url.endsWith('/')) url = url.substring(0, url.length - 1);
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  return url;
}

/// Whether [host] names something only reachable from inside the household's
/// own network.
///
/// A watch linked to its phone over Bluetooth is handed the phone's *internet*,
/// not the phone's *network*: the companion proxy routes as though the request
/// came from the open web, so an address like this has no route through it while
/// the link is perfectly healthy. What the answer is for is telling that wearer
/// the truth — their watch is connected, and this server still needs Wi-Fi.
///
/// A yes here is reliable. **A no is not**: split-horizon DNS resolves an
/// ordinary public name to a private address at home, and nothing visible in
/// the address says so. So this may confirm what a failure already showed, and
/// may spare a request that was never going to arrive, but it can never be what
/// decides that a server is reachable.
bool isPrivateHost(String host) {
  final name = host.trim().toLowerCase();
  if (name.isEmpty) return false;
  // A bracketed IPv6 literal, as a URL spells it.
  final bare = name.startsWith('[') && name.endsWith(']')
      ? name.substring(1, name.length - 1)
      : name;
  if (bare == 'localhost') return true;

  final v4 = _ipv4(bare);
  if (v4 != null) {
    return v4[0] == 10 ||
        v4[0] == 127 ||
        (v4[0] == 192 && v4[1] == 168) ||
        (v4[0] == 172 && v4[1] >= 16 && v4[1] <= 31) ||
        // Link-local: what a device gives itself when nothing assigned it one.
        (v4[0] == 169 && v4[1] == 254);
  }

  if (bare.contains(':')) {
    final v6 = bare.split('%').first;
    if (v6 == '::1') return true;
    // fc00::/7 unique-local and fe80::/10 link-local, by the only part of the
    // address that decides either.
    return v6.startsWith('fc') ||
        v6.startsWith('fd') ||
        v6.startsWith('fe8') ||
        v6.startsWith('fe9') ||
        v6.startsWith('fea') ||
        v6.startsWith('feb');
  }

  for (final suffix in const [
    '.local',
    '.lan',
    '.home',
    '.home.arpa',
    '.internal',
    '.intranet',
    '.localdomain',
  ]) {
    if (name.endsWith(suffix)) return true;
  }

  // A name with no dot at all resolves only against whatever local suffix the
  // network hands out, so it cannot be reached from anywhere else.
  return !name.contains('.');
}

/// [host] as four octets, or null when it is not an IPv4 literal. Hand-parsed
/// because `InternetAddress` is `dart:io`, which core does not get on web.
List<int>? _ipv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return null;
    final value = int.tryParse(part);
    if (value == null || value < 0 || value > 255) return null;
    octets.add(value);
  }
  return octets;
}
