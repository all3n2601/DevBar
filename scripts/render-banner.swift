import AppKit
import WebKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let source = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let svg = try String(contentsOf: source, encoding: .utf8)
let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 1200, height: 380))
let window = NSWindow(contentRect: web.frame, styleMask: .borderless, backing: .buffered, defer: false)
window.contentView = web
window.orderFront(nil)
web.loadHTMLString("<html><head><style>html,body{margin:0;width:1200px;height:380px;background:transparent}svg{display:block}</style></head><body>\(svg)</body></html>", baseURL: source.deletingLastPathComponent())
let deadline = Date().addingTimeInterval(15)
while web.isLoading && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
RunLoop.current.run(until: Date().addingTimeInterval(0.5))
var finished = false
var failure: Error?
let configuration = WKSnapshotConfiguration()
configuration.rect = web.bounds
configuration.snapshotWidth = 1200
web.takeSnapshot(with: configuration) { image, error in
    do {
        if let error = error { throw error }
        guard let tiff = image?.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else { throw NSError(domain: "render", code: 1) }
        try data.write(to: output)
    } catch { failure = error }
    finished = true
}
while !finished && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
window.orderOut(nil)
if !finished || failure != nil { fputs("Banner rendering failed: \(String(describing: failure))\n", stderr); exit(1) }
