// capture-png.swift: draw each screenshot SVG with WebKit and write a PNG of
// exactly its width and height, one pixel per unit (D23 to D25 in
// features/598-screenshot-capture.md). Compiled and run by
// build/capture-screenshots.pl:
//
//   swiftc -O -o DIR/capture-png build/capture-png.swift
//   DIR/capture-png IMAGE.svg OUT.png [IMAGE.svg OUT.png ...]
//
// Each SVG is loaded as a document in an off-screen WKWebView sized to it and
// snapshotted; the snapshot, taken at the display's scale, is drawn into a
// bitmap of the SVG's width and height in pixels. The tool writes images a
// whole number of units wide and high (D25), so nothing is stretched.
import AppKit
import WebKit

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("capture-png: \(message)\n".data(using: .utf8)!)
    exit(1)
}

let args = Array(CommandLine.arguments.dropFirst())
guard !args.isEmpty, args.count % 2 == 0 else { fail("usage: capture-png IMAGE.svg OUT.png [IMAGE.svg OUT.png ...]") }
let jobs = stride(from: 0, to: args.count, by: 2).map {
    (svg: URL(fileURLWithPath: args[$0]).absoluteURL, png: URL(fileURLWithPath: args[$0 + 1]).absoluteURL)
}

// The SVG's width and height in units, from its root element; whole numbers.
func size(of svg: URL) -> (Int, Int) {
    guard let text = try? String(contentsOf: svg, encoding: .utf8) else { fail("cannot read \(svg.path)") }
    guard let root = text.range(of: "<svg [^>]*>", options: .regularExpression) else { fail("\(svg.path): no <svg> element") }
    let tag = String(text[root])
    func attribute(_ name: String) -> Int {
        guard let r = tag.range(of: " \(name)=\"[0-9]+\"", options: .regularExpression),
              let value = Int(tag[r].split(separator: "\"")[1]), value > 0
        else { fail("\(svg.path): the \(name) is not a whole number of units") }
        return value
    }
    return (attribute("width"), attribute("height"))
}

final class Snapshotter: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    let window: NSWindow
    var remaining: [(svg: URL, png: URL)]
    var current: (svg: URL, png: URL, width: Int, height: Int)?

    init(jobs: [(svg: URL, png: URL)]) {
        remaining = jobs
        let frame = NSRect(x: 0, y: 0, width: 1, height: 1)
        window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        webView = WKWebView(frame: frame)
        super.init()
        webView.navigationDelegate = self
        window.contentView = webView
    }

    func next() {
        guard !remaining.isEmpty else { exit(0) }
        let job = remaining.removeFirst()
        let (width, height) = size(of: job.svg)
        current = (job.svg, job.png, width, height)
        window.setContentSize(NSSize(width: width, height: height))
        webView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        webView.loadFileURL(job.svg, allowingReadAccessTo: job.svg.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let job = current else { return }
        // One pause after the load lets layout and fonts settle before the snapshot.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            let config = WKSnapshotConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: job.width, height: job.height)
            config.afterScreenUpdates = true
            webView.takeSnapshot(with: config) { [self] image, error in
                guard let image = image else { fail("\(job.svg.path): snapshot failed: \(String(describing: error))") }
                write(image, job.width, job.height, to: job.png)
                next()
            }
        }
    }

    func write(_ image: NSImage, _ width: Int, _ height: Int, to png: URL) {
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { fail("\(png.path): cannot allocate a \(width) x \(height) bitmap") }
        rep.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        guard let data = rep.representation(using: .png, properties: [:]) else { fail("\(png.path): cannot encode the PNG") }
        do { try data.write(to: png) } catch { fail("cannot write \(png.path): \(error.localizedDescription)") }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail("\(current?.svg.path ?? ""): load failed: \(error.localizedDescription)")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail("\(current?.svg.path ?? ""): load failed: \(error.localizedDescription)")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let snapshotter = Snapshotter(jobs: jobs)
DispatchQueue.main.async { snapshotter.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 30 + 5 * Double(jobs.count)) { fail("timed out") }
app.run()
