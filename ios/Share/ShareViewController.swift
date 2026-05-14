import UIKit

class ShareViewController: RSIShareViewController {
    // Inherits default behavior from `RSIShareViewController` (vendored in
    // RSIShareViewController.swift): collect the shared payload (images,
    // text, URLs), persist it to the App Group's UserDefaults, then open
    // the host app via the registered URL scheme. Override
    // `shouldAutoRedirect()` to return `false` if a custom share sheet UI
    // is needed before posting.
}
