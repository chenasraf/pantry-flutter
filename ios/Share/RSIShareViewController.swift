// Vendored from receive_sharing_intent 1.8.1 so the Share Extension does
// not need to import the pod (which transitively pulls in Flutter +
// UIApplication APIs that are banned in app extensions).
//
// Keep the constants and `SharedMediaFile` / `SharedMediaType` shapes in
// sync with `SwiftReceiveSharingIntentPlugin.swift` in the upstream pod,
// otherwise the host app side will not decode payloads correctly.

import UIKit
import Social
import MobileCoreServices
import Photos
import UniformTypeIdentifiers

let kSchemePrefix = "ShareMedia"
let kUserDefaultsKey = "ShareKey"
let kUserDefaultsMessageKey = "ShareMessageKey"
let kAppGroupIdKey = "AppGroupId"

class SharedMediaFile: Codable {
    var path: String
    var mimeType: String?
    var thumbnail: String?
    var duration: Double?
    var message: String?
    var type: SharedMediaType

    init(
        path: String,
        mimeType: String? = nil,
        thumbnail: String? = nil,
        duration: Double? = nil,
        message: String? = nil,
        type: SharedMediaType
    ) {
        self.path = path
        self.mimeType = mimeType
        self.thumbnail = thumbnail
        self.duration = duration
        self.message = message
        self.type = type
    }
}

enum SharedMediaType: String, Codable, CaseIterable {
    case image
    case video
    case text
    case file
    case url

    var toUTTypeIdentifier: String {
        if #available(iOS 14.0, *) {
            switch self {
            case .image: return UTType.image.identifier
            case .video: return UTType.movie.identifier
            case .text: return UTType.text.identifier
            case .file: return UTType.fileURL.identifier
            case .url: return UTType.url.identifier
            }
        }
        switch self {
        case .image: return "public.image"
        case .video: return "public.movie"
        case .text: return "public.text"
        case .file: return "public.file-url"
        case .url: return "public.url"
        }
    }
}

@available(swift, introduced: 5.0)
open class RSIShareViewController: SLComposeServiceViewController {
    var hostAppBundleIdentifier = ""
    var appGroupId = ""
    var sharedMedia: [SharedMediaFile] = []

    open func shouldAutoRedirect() -> Bool { true }

    open override func isContentValid() -> Bool { true }

    open override func viewDidLoad() {
        super.viewDidLoad()
        loadIds()
    }

    open override func didSelectPost() {
        saveAndRedirect(message: contentText)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let content = extensionContext!.inputItems[0] as? NSExtensionItem,
           let contents = content.attachments {
            for (index, attachment) in contents.enumerated() {
                for type in SharedMediaType.allCases {
                    if attachment.hasItemConformingToTypeIdentifier(type.toUTTypeIdentifier) {
                        attachment.loadItem(forTypeIdentifier: type.toUTTypeIdentifier) { [weak self] data, error in
                            guard let this = self, error == nil else {
                                self?.dismissWithError()
                                return
                            }
                            switch type {
                            case .text:
                                if let text = data as? String {
                                    this.handleMedia(forLiteral: text, type: type, index: index, content: content)
                                }
                            case .url:
                                if let url = data as? URL {
                                    this.handleMedia(forLiteral: url.absoluteString, type: type, index: index, content: content)
                                }
                            default:
                                if let url = data as? URL {
                                    this.handleMedia(forFile: url, type: type, index: index, content: content)
                                } else if let image = data as? UIImage {
                                    this.handleMedia(forUIImage: image, type: type, index: index, content: content)
                                }
                            }
                        }
                        break
                    }
                }
            }
        }
    }

    open override func configurationItems() -> [Any]! { [] }

    private func loadIds() {
        let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier!
        let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".")
        hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint!])
        let defaultAppGroupId = "group.\(hostAppBundleIdentifier)"
        let customAppGroupId = Bundle.main.object(forInfoDictionaryKey: kAppGroupIdKey) as? String
        appGroupId = customAppGroupId ?? defaultAppGroupId
    }

    private func handleMedia(forLiteral item: String, type: SharedMediaType, index: Int, content: NSExtensionItem) {
        sharedMedia.append(SharedMediaFile(
            path: item,
            mimeType: type == .text ? "text/plain" : nil,
            type: type
        ))
        if index == (content.attachments?.count ?? 0) - 1, shouldAutoRedirect() {
            saveAndRedirect()
        }
    }

    private func handleMedia(forUIImage image: UIImage, type: SharedMediaType, index: Int, content: NSExtensionItem) {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            if index == (content.attachments?.count ?? 0) - 1, shouldAutoRedirect() {
                saveAndRedirect()
            }
            return
        }
        let tempPath = containerURL.appendingPathComponent("TempImage.png")
        if writeTempFile(image, to: tempPath) {
            let newPathDecoded = tempPath.absoluteString.removingPercentEncoding!
            sharedMedia.append(SharedMediaFile(
                path: newPathDecoded,
                mimeType: type == .image ? "image/png" : nil,
                type: type
            ))
        }
        if index == (content.attachments?.count ?? 0) - 1, shouldAutoRedirect() {
            saveAndRedirect()
        }
    }

    private func handleMedia(forFile url: URL, type: SharedMediaType, index: Int, content: NSExtensionItem) {
        let fileName = getFileName(from: url, type: type)
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            if index == (content.attachments?.count ?? 0) - 1, shouldAutoRedirect() {
                saveAndRedirect()
            }
            return
        }
        let newPath = containerURL.appendingPathComponent(fileName)

        if copyFile(at: url, to: newPath) {
            let newPathDecoded = newPath.absoluteString.removingPercentEncoding!
            if type == .video, let videoInfo = getVideoInfo(from: url) {
                let thumbnailPathDecoded = videoInfo.thumbnail?.removingPercentEncoding
                sharedMedia.append(SharedMediaFile(
                    path: newPathDecoded,
                    mimeType: url.mimeType(),
                    thumbnail: thumbnailPathDecoded,
                    duration: videoInfo.duration,
                    type: type
                ))
            } else {
                sharedMedia.append(SharedMediaFile(
                    path: newPathDecoded,
                    mimeType: url.mimeType(),
                    type: type
                ))
            }
        }

        if index == (content.attachments?.count ?? 0) - 1, shouldAutoRedirect() {
            saveAndRedirect()
        }
    }

    private func saveAndRedirect(message: String? = nil) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        userDefaults?.set(toData(data: sharedMedia), forKey: kUserDefaultsKey)
        userDefaults?.set(message, forKey: kUserDefaultsMessageKey)
        userDefaults?.synchronize()
        redirectToHostApp()
    }

    private func redirectToHostApp() {
        loadIds()
        let url = URL(string: "\(kSchemePrefix)-\(hostAppBundleIdentifier):share")!
        var responder = self as UIResponder?
        // iOS 18 removed the legacy `openURL:` selector, so we have to
        // walk the responder chain and call `UIApplication.open(_:)`
        // through the dynamic cast — this path is what the upstream
        // receive_sharing_intent package uses.
        if #available(iOS 18.0, *) {
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                }
                responder = responder?.next
            }
        } else {
            let selectorOpenURL = sel_registerName("openURL:")
            while responder != nil {
                if responder?.responds(to: selectorOpenURL) == true {
                    _ = responder?.perform(selectorOpenURL, with: url)
                }
                responder = responder?.next
            }
        }
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func dismissWithError() {
        let alert = UIAlertController(title: "Error", message: "Error loading data", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func getFileName(from url: URL, type: SharedMediaType) -> String {
        var name = url.lastPathComponent
        if name.isEmpty {
            switch type {
            case .image: name = UUID().uuidString + ".png"
            case .video: name = UUID().uuidString + ".mp4"
            case .text: name = UUID().uuidString + ".txt"
            default: name = UUID().uuidString
            }
        }
        return name
    }

    private func writeTempFile(_ image: UIImage, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try image.pngData()?.write(to: dstURL)
            return true
        } catch {
            return false
        }
    }

    private func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch {
            return false
        }
        return true
    }

    private func getVideoInfo(from url: URL) -> (thumbnail: String?, duration: Double)? {
        let asset = AVAsset(url: url)
        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
        let thumbnailPath = getThumbnailPath(for: url)

        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            return (thumbnail: thumbnailPath.absoluteString, duration: duration)
        }

        var saved = false
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.maximumSize = CGSize(width: 360, height: 360)
        do {
            let img = try assetImgGenerate.copyCGImage(
                at: CMTimeMakeWithSeconds(600, preferredTimescale: 1),
                actualTime: nil
            )
            try UIImage(cgImage: img).pngData()?.write(to: thumbnailPath)
            saved = true
        } catch {
            saved = false
        }

        return saved ? (thumbnail: thumbnailPath.absoluteString, duration: duration) : nil
    }

    private func getThumbnailPath(for url: URL) -> URL {
        let fileName = Data(url.lastPathComponent.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "==", with: "")
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!
            .appendingPathComponent("\(fileName).jpg")
    }

    private func toData(data: [SharedMediaFile]) -> Data {
        try! JSONEncoder().encode(data)
    }
}

extension URL {
    func mimeType() -> String {
        if #available(iOS 14.0, *) {
            if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
                return mimeType
            }
        } else {
            if let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension, pathExtension as NSString, nil
            )?.takeRetainedValue(),
               let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}
