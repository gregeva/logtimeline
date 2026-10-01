// snapshot.swift: draw an SVG with WebKit and write a PNG of its own size.
//
//   swiftc -O -o <scratch>/snapshot prototype/650-png/snapshot.swift
//   <scratch>/snapshot IMAGE.svg OUT.png
//
// The SVG is loaded as a document in an off-screen WKWebView sized to the
// SVG's width and height (rounded up), snapshotted, and the snapshot drawn
// into a bitmap of exactly round(width) x round(height) pixels.
import AppKit
import WebKit

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: snapshot IMAGE.svg OUT.png\n".data(using: .utf8)!)
    exit(2)
}
let svgURL = URL(fileURLWithPath: args[1]).absoluteURL
let pngURL = URL(fileURLWithPath: args[2]).absoluteURL

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("snapshot: \(message)\n".data(using: .utf8)!)
    exit(1)
}

// The SVG's width and height in units, from its root element.
guard let svgText = try? String(contentsOf: svgURL, encoding: .utf8) else { fail("cannot read \(svgURL.path)") }
func attribute(_ name: String) -> Double? {
    guard let root = svgText.range(of: "<svg [^>]*>", options: .regularExpression) else { return nil }
    let tag = String(svgText[root])
    guard let r = tag.range(of: " \(name)=\"[0-9.]+\"", options: .regularExpression) else { return nil }
    return Double(tag[r].split(separator: "\"")[1])
}
guard let width = attribute("width"), let height = attribute("height") else { fail("no width and height on the root element") }
let pixelsWide = Int(width.rounded()), pixelsHigh = Int(height.rounded())

final class Snapshotter: NSObject, WKNavigationDelegate {
    let width: Double, height: Double, pixelsWide: Int, pixelsHigh: Int, pngURL: URL
    init(width: Double, height: Double, pixelsWide: Int, pixelsHigh: Int, pngURL: URL) {
        self.width = width; self.height = height; self.pixelsWide = pixelsWide; self.pixelsHigh = pixelsHigh; self.pngURL = pngURL
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Fonts are system fonts; one turn of the run loop lets layout settle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            let config = WKSnapshotConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: width, height: height)
            config.afterScreenUpdates = true
            webView.takeSnapshot(with: config) { [self] image, error in
                guard let image = image else { fail("snapshot failed: \(String(describing: error))") }
                guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh,
                                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                                 colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { fail("no bitmap") }
                rep.size = NSSize(width: pixelsWide, height: pixelsHigh)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
                NSGraphicsContext.current?.imageInterpolation = .high
                image.draw(in: NSRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh))
                NSGraphicsContext.restoreGraphicsState()
                guard let png = rep.representation(using: .png, properties: [:]) else { fail("cannot encode PNG") }
                do { try png.write(to: pngURL) } catch { fail("cannot write \(pngURL.path): \(error)") }
                exit(0)
            }
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail("load failed: \(error)") }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail("load failed: \(error)") }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let frame = NSRect(x: 0, y: 0, width: width.rounded(.up), height: height.rounded(.up))
let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
let webView = WKWebView(frame: frame)
let delegate = Snapshotter(width: width, height: height, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh, pngURL: pngURL)
webView.navigationDelegate = delegate
window.contentView = webView
webView.loadFileURL(svgURL, allowingReadAccessTo: svgURL.deletingLastPathComponent())
DispatchQueue.main.asyncAfter(deadline: .now() + 20) { fail("timed out") }
app.run()
