import ScreenSaver
import CoreGraphics
@objc(FractalClockAbsoluteView)
class FractalClockAbsoluteView: ScreenSaverView {
    
    struct Rotator {
        var cos: CGFloat
        var sin: CGFloat
    }

    struct Color {
        var r: CGFloat
        var g: CGFloat
        var b: CGFloat
    }
    
    let framesPerSecond = 30.0
    let colorAdjustment: CGFloat = 0.85
    let maxDepth = 32
    
    var accumulatedSeconds: TimeInterval = 0
    var accumulatedFrames: Int = 0
    var framesBetweenDepthChanges: Double = 30.0
    var targetDepth: Int = 11
    
    var lastFrameTime: TimeInterval = 0
    var totalPixelCount: CGFloat = 0
    
    private var alphaCache: [CGFloat] = []

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.animationTimeInterval = 1.0 / framesPerSecond
        self.lastFrameTime = Date.timeIntervalSinceReferenceDate
        
        // Precalculate alphas to avoid 'pow' calls in the hot loop
        alphaCache = (0...maxDepth).map { d in
            if d == 0 { return 1.0 }
            return CGFloat(pow(Double(d), -1.0))
        }
    }
    
    override func startAnimation() {
        super.startAnimation()
        targetDepth = isPreview ? 8 : 11
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
        
        // Background
        context.setFillColor(NSColor.black.cgColor)
        context.fill(bounds)
        
        // Draw the clock
        let (root, r0, r1) = getRootAndRotators(isPreview: isPreview, bounds: bounds)
        
        context.setLineWidth(2.0)
        context.setLineCap(.butt) // Faster than .round and usually looks fine for fractals
        context.setBlendMode(.normal)
        
        let rootColor = Color(r: 1.0, g: 1.0, b: 1.0)
        drawBranch(context: context, origin: root.origin, vector: root.size, r0: r0, r1: r1, depth: 0, depthLeft: targetDepth, color: rootColor)
        
        // Accumulate exactly how long drawing took
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
    
    private func drawBranch(context: CGContext, origin: CGPoint, vector: CGSize, r0: Rotator, r1: Rotator, depth: Int, depthLeft: Int, color: Color) {
        let p2 = CGPoint(x: origin.x + vector.width, y: origin.y + vector.height)
        
        // Optimization: Prune branches that are too small to be meaningful
        // Using a squared length for faster comparison
        let lengthSq = vector.width * vector.width + vector.height * vector.height
        if lengthSq < 0.25 { // Half a pixel
            return
        }

        if depthLeft >= 1 {
            // Left branch
            let colorLeft = Color(
                r: colorAdjustment * color.r,
                g: 0.92 * color.g,
                b: 0.1 + colorAdjustment * color.b
            )
            let vectorLeft = rotateSize(rotator: r0, s0: vector)
            drawBranch(context: context, origin: p2, vector: vectorLeft, r0: r0, r1: r1, depth: depth + 1, depthLeft: depthLeft - 1, color: colorLeft)
            
            // Right branch
            let colorRight = Color(
                r: 0.1 + colorAdjustment * color.r,
                g: 0.92 * color.g,
                b: colorAdjustment * color.b
            )
            let vectorRight = rotateSize(rotator: r1, s0: vector)
            drawBranch(context: context, origin: p2, vector: vectorRight, r0: r0, r1: r1, depth: depth + 1, depthLeft: depthLeft - 1, color: colorRight)
        }
        
        let alpha = alphaCache[min(depth, maxDepth)]
        context.setStrokeColor(red: color.r, green: color.g, blue: color.b, alpha: alpha)
        
        context.beginPath()
        if depth == 0 {
            context.move(to: CGPoint(x: origin.x + vector.width * 0.5, y: origin.y + vector.height * 0.5))
        } else {
            context.move(to: origin)
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
