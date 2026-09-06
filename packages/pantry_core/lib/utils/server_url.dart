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
