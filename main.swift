import Cocoa
import ScreenSaver

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var clockView: FractalClockView!
    var timer: Timer!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Fractal Clock Test"
        
        clockView = FractalClockView(frame: window.contentView!.bounds, isPreview: false)
        clockView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(clockView)
        
        window.makeKeyAndOrderFront(nil)
        
        clockView.startAnimation()
        
        timer = Timer.scheduledTimer(withTimeInterval: clockView.animationTimeInterval, repeats: true) { _ in
            self.clockView.animateOneFrame()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
