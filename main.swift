import Cocoa
import ScreenSaver

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var clockView: FractalClockAbsoluteView!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Fractal Clock Test"
        
        clockView = FractalClockAbsoluteView(frame: window.contentView!.bounds, isPreview: false)
        clockView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(clockView)
        
        window.makeKeyAndOrderFront(nil)
        
        clockView.startAnimation()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
