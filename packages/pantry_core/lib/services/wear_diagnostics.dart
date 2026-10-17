/// The wire contract for reading a watch's diagnostic log from its phone.
///
/// The phone asks and the watch answers: the log lives on the watch, and the
/// phone is where there is a screen big enough to read it and a share sheet to
/// send it from. An older watch that does not know these paths never answers,
/// which the asking side treats as a watch it could not reach.
class WearDiagnostics {
  WearDiagnostics._();

  /// Phone → watch, carrying `{id}`. A message, so it only reaches a watch
  /// whose app is running — the only kind that can answer it.
  static const requestPath = '/diagnostics/request';

  /// Watch → phone, carrying `{id, log}`. A channel, because a log runs to
  /// hundreds of kilobytes and a message is capped far below that.
  static const responsePath = '/diagnostics/response';

  static const timeout = Duration(seconds: 15);
}
