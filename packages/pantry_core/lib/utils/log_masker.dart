/// Strips what identifies a person or a server from a log line, so a log can
/// be handed to anyone.
///
/// Applied when a line is written, not only when it is shared: a line on disk
/// is a line that can leave the device, and the credential that names the
/// server may not exist yet when the line is written — so every URL host is
/// masked whether or not it is known to be the server.
class LogMasker {
  /// The signed-in server's host, masked as `<server>` wherever it appears
  /// bare, as in a failed host lookup.
  final String? serverHost;

  /// The signed-in login name, masked as `<user>`.
  final String? loginName;

  const LogMasker({this.serverHost, this.loginName});

  static final _auth = RegExp(
    r'\b(Basic|Bearer)\s+[A-Za-z0-9+/=._~-]+',
    caseSensitive: false,
  );
  static final _urlHost = RegExp(
    r'\b([a-z][a-z0-9+.-]*://)(?:[^@/\s]*@)?(\[[^\]]*\]|[^/\s:?#"'
    "'"
    r']+)',
    caseSensitive: false,
  );
  static final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final _ipv4 = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');

  /// App passwords, push endpoints and session tokens are long runs of the
  /// base64 / URL-safe alphabet; nothing worth reading in a log is. A slash
  /// ends a run, or every long request path would read as a token.
  static final _token = RegExp(r'[A-Za-z0-9+_-]{32,}={0,2}');

  /// An app password made by hand in Nextcloud's security settings: five
  /// groups of five, short enough to slip under [_token].
  static final _appPassword = RegExp(
    r'\b[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}\b',
  );

  String mask(String input) {
    var out = input.replaceAllMapped(_auth, (m) => '${m[1]} <redacted>');
    out = out.replaceAllMapped(_urlHost, (m) {
      final host = m[2]!;
      final known =
          serverHost != null && host.toLowerCase() == serverHost!.toLowerCase();
      return '${m[1]}${known ? '<server>' : '<host>'}';
    });
    out = out.replaceAll(_email, '<email>');
    final host = serverHost;
    if (host != null && host.isNotEmpty) {
      out = out.replaceAll(
        RegExp(RegExp.escape(host), caseSensitive: false),
        '<server>',
      );
    }
    out = out.replaceAll(_ipv4, '<ip>');
    final login = loginName;
    // A one- or two-letter login would mask every word containing it.
    if (login != null && login.length > 2) {
      out = out.replaceAll(
        RegExp(
          '(?<![\\w.-])${RegExp.escape(login)}(?![\\w-])',
          caseSensitive: false,
        ),
        '<user>',
      );
    }
    return out
        .replaceAll(_token, '<token>')
        .replaceAll(_appPassword, '<token>');
  }
}
