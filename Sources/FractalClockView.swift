import ScreenSaver
import CoreGraphics
@objc(FractalClockAbsoluteView)
class FractalClockAbsoluteView: ScreenSaverView {
    
    struct Rotator {
        var cos: CGFloat
        var sin: CGFloat
    }
    
    let framesPerSecond = 30.0
    let colorAdjustment: CGFloat = 0.85
    let maxDepth = 32
    
    var accumulatedSeconds: TimeInterval = 0
    var accumulatedFrames: Int = 0
    var framesBetweenDepthChanges: Double = 30.0
    var targetDepth: Int = 4
    
    var lastFrameTime: TimeInterval = 0
    var totalPixelCount: CGFloat = 0
    


    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 / framesPerSecond
        self.lastFrameTime = Date.timeIntervalSinceReferenceDate
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / framesPerSecond
        self.lastFrameTime = Date.timeIntervalSinceReferenceDate
    }
    
    override func startAnimation() {
        super.startAnimation()
        targetDepth = 4
        framesBetweenDepthChanges = framesPerSecond
        accumulatedFrames = 0
        accumulatedSeconds = 0
        lastFrameTime = Date.timeIntervalSinceReferenceDate
    }
    
    override func stopAnimation() {
        super.stopAnimation()
    }
    
    override var isOpaque: Bool {
        return true
    }
    
    override func draw(_ rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let startTime = Date.timeIntervalSinceReferenceDate
        accumulatedFrames += 1
        
        // Remove dynamic framerate profiling completely, as MacOS ScreenSaver engine overhead
        // causes false positives and drastically shrinks the fractal incorrectly.
        // Hardcode the target depth to 11.
        targetDepth = 11

        
        // Background
        context.setFillColor(NSColor.black.cgColor)
        context.fill(bounds)
        
        // Draw the clock
        let (root, r0, r1) = getRootAndRotators(isPreview: isPreview, bounds: bounds)
        
        context.setLineWidth(2.0)
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        
        let rootColor: [CGFloat] = [1.0, 1.0, 1.0]
        drawBranch(context: context, line: root, r0: r0, r1: r1, depth: 0, depthLeft: targetDepth, color: rootColor)
        
        // Accumulate exactly how long drawing took to compute maximum theoretical FPS
        let drawDuration = Date.timeIntervalSinceReferenceDate - startTime
        accumulatedSeconds += drawDuration
    }
    
    override func animateOneFrame() {
        self.needsDisplay = true
    }
    
    override var hasConfigureSheet: Bool {
        return false
    }
    
    override var configureSheet: NSWindow? {
        return nil
    }
    
    // MARK: - Drawing Logic
    
    private func getRootAndRotators(isPreview: Bool, bounds: NSRect) -> (NSRect, Rotator, Rotator) {
        let now = getNow(isPreview: isPreview)
        let hourRotation = getRotation(now: now, period: 12 * 60 * 60)
        let minuteRotation = getRotation(now: now, period: 60 * 60)
        let secondRotation = getRotation(now: now, period: 60)
        
        let scale = transition(now: now, transitionSeconds: 12.0, periods: [
            (61.0, 1.0),
            (61.0, 0.793700525984099737375852819636) // cube root of 1/2
        ])
        
        let r0 = initRotator(rotation: secondRotation - hourRotation, scale: -scale)
        let r1 = initRotator(rotation: minuteRotation - hourRotation, scale: -scale)
        
        let r = initRotator(rotation: hourRotation, scale: 1.0)
        let rootSize = min(bounds.size.width, bounds.size.height) / 6.0
        
        var root = NSRect.zero
        root.size = rotateSize(rotator: r, s0: NSSize(width: -rootSize, height: 0))
        root.origin.x = bounds.midX - root.size.width
        root.origin.y = bounds.midY - root.size.height
        
        return (root, r0, r1)
    }
    
    private func drawBranch(context: CGContext, line: NSRect, r0: Rotator, r1: Rotator, depth: Int, depthLeft: Int, color: [CGFloat]) {
        let p2 = CGPoint(x: line.origin.x + line.size.width, y: line.origin.y + line.size.height)
        
        if depthLeft >= 1 {
            var newLine = NSRect(origin: p2, size: .zero)
            
            var newColorLeft = color
            newColorLeft[1] = 0.92 * color[1]
            newLine.size = rotateSize(rotator: r0, s0: line.size)
            newColorLeft[0] = colorAdjustment * color[0]
            newColorLeft[2] = 0.1 + colorAdjustment * color[2]
            drawBranch(context: context, line: newLine, r0: r0, r1: r1, depth: depth + 1, depthLeft: depthLeft - 1, color: newColorLeft)
            
            var newColorRight = color
            newColorRight[1] = 0.92 * color[1]
            newLine.size = rotateSize(rotator: r1, s0: line.size)
            newColorRight[0] = 0.1 + colorAdjustment * color[0]
            newColorRight[2] = colorAdjustment * color[2]
            drawBranch(context: context, line: newLine, r0: r0, r1: r1, depth: depth + 1, depthLeft: depthLeft - 1, color: newColorRight)
        }
        
        let alpha = depth == 0 ? 1.0 : pow(Double(depth), -1.0)
        context.setStrokeColor(red: color[0], green: color[1], blue: color[2], alpha: CGFloat(alpha))
        
        context.beginPath()
        if depth == 0 {
            context.move(to: CGPoint(x: line.origin.x + line.size.width * 0.5, y: line.origin.y + line.size.height * 0.5))
        } else {
            context.move(to: line.origin)
        }
        context.addLine(to: p2)
        context.strokePath()
    }
    
    private func getNow(isPreview: Bool) -> Double {
        var now = Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
        var tt = time_t(now)
        var tms = tm()
        localtime_r(&tt, &tms)
        
        now = Double((tms.tm_hour * 60) + tms.tm_min) * 60.0 + Double(tms.tm_sec) + now.truncatingRemainder(dividingBy: 1.0)
        if isPreview {
            now = (now * 6).truncatingRemainder(dividingBy: 60 * 60 * 24)
        }
        return now
    }
    
    private func getRotation(now: Double, period: Double) -> Double {
        return 0.25 - now.truncatingRemainder(dividingBy: period) / period
    }
    
    private func initRotator(rotation: Double, scale: Double) -> Rotator {
        let radians = 2.0 * .pi * rotation
        return Rotator(cos: CGFloat(cos(radians) * scale), sin: CGFloat(sin(radians) * scale))
    }
    
    private func rotateSize(rotator: Rotator, s0: NSSize) -> NSSize {
        return NSSize(
            width: s0.width * rotator.cos - s0.height * rotator.sin,
            height: s0.width * rotator.sin + s0.height * rotator.cos
        )
    }
    
    private func transition(now: Double, transitionSeconds: Double, periods: [(Double, Double)]) -> Double {
        let totalSeconds = periods.reduce(0) { $0 + $1.0 + transitionSeconds }
        var modnow = now.truncatingRemainder(dividingBy: totalSeconds)
        let level0 = periods.first?.1 ?? 0
        
        var startLevel: Double = 0
        var endLevel: Double = 0
        
        for i in 0..<periods.count {
            let (duration, level) = periods[i]
            startLevel = level
            
            if modnow < duration {
                endLevel = startLevel
                break
            }
            
            modnow -= duration
            if modnow <= transitionSeconds {
                endLevel = (i + 1 < periods.count) ? periods[i + 1].1 : level0
                break
            }
            
            modnow -= transitionSeconds
        }
        
        if startLevel == endLevel {
            return startLevel
        } else {
            return endLevel + (startLevel - endLevel) * (cos(.pi * modnow / transitionSeconds) + 1.0) * 0.5
        }
    }
}
