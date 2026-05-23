import AuthenticationServices
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Hide title bar but keep traffic-light buttons; let Flutter content
    // draw under the chrome.
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    AuthSessionChannel.register(with: flutterViewController)

    super.awakeFromNib()
  }
}

@available(macOS 10.15, *)
final class AuthSessionChannel: NSObject, ASWebAuthenticationPresentationContextProviding {
  private var session: ASWebAuthenticationSession?
  private var pendingResult: FlutterResult?

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "dev.casraf.pantry/auth_session",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let instance = AuthSessionChannel()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString),
            let scheme = args["callbackScheme"] as? String
      else {
        result(FlutterError(code: "BAD_ARGS", message: "url and callbackScheme required", details: nil))
        return
      }
      // If a previous session is still pending, cancel it first.
      cancelInternal(reason: "REPLACED")
      pendingResult = result
      let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { [weak self] callbackUrl, error in
        guard let self else { return }
        let pending = self.pendingResult
        self.pendingResult = nil
        self.session = nil
        if let error {
          if case ASWebAuthenticationSessionError.canceledLogin = error {
            pending?(FlutterError(code: "CANCELED", message: "Session canceled", details: nil))
          } else {
            pending?(FlutterError(code: "EUNKNOWN", message: error.localizedDescription, details: nil))
          }
          return
        }
        pending?(callbackUrl?.absoluteString)
      }
      session.presentationContextProvider = self
      self.session = session
      session.start()

    case "cancel":
      cancelInternal(reason: "CANCELED_BY_APP")
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func cancelInternal(reason: String) {
    guard let session else { return }
    session.cancel()
    self.session = nil
    if let pending = pendingResult {
      pendingResult = nil
      pending(FlutterError(code: reason, message: "Session dismissed", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return NSApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
  }
}
