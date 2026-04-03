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
    
    // Adaptive settings
    var framesPerSecond: Double {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return 2.0 // Radical savings
        }
        return 15.0 // High efficiency
    }
    
    var currentTargetDepth: Int {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return 8 // 2^8 branches instead of 2^11
        }
        return 11
    }

    let colorAdjustment: CGFloat = 0.85
    let maxDepth = 32
    
    var accumulatedSeconds: TimeInterval = 0
    var accumulatedFrames: Int = 0
    var lastFrameTime: TimeInterval = 0
    
    private var alphaCache: [CGFloat] = []
    private var depthPaths: [CGMutablePath] = []

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.animationTimeInterval = 1.0 / 15.0
        self.lastFrameTime = Date.timeIntervalSinceReferenceDate
        
        alphaCache = (0...maxDepth).map { d in
            if d == 0 { return 1.0 }
            return CGFloat(pow(Double(d), -1.0))
        }

        // Initialize paths for batching
        depthPaths = (0...maxDepth).map { _ in CGMutablePath() }
    }
    
    override func startAnimation() {
        super.startAnimation()
        self.animationTimeInterval = 1.0 / framesPerSecond
        accumulatedFrames = 0
        accumulatedSeconds = 0
    }
    
    override func draw(_ rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let startTime = Date.timeIntervalSinceReferenceDate
        
        // Clear background
        context.setFillColor(NSColor.black.cgColor)
        context.fill(bounds)
        
        // Update timing for next frame
        self.animationTimeInterval = 1.0 / framesPerSecond
        
        let (root, r0, r1) = getRootAndRotators(isPreview: isPreview, bounds: bounds)
        let depthLimit = currentTargetDepth
        
        // Reset paths
        for d in 0...depthLimit {
            depthPaths[d] = CGMutablePath()
        }
        
        // Build paths recursively (no drawing yet)
        buildPaths(origin: root.origin, vector: root.size, r0: r0, r1: r1, depth: 0, depthLeft: depthLimit)
        
        // Batch draw by depth
        context.setLineWidth(2.0)
        context.setLineCap(.butt)
        
        // We use a simplified color model for batched drawing to save thousands of state changes.
        // The color is now depth-based, which is the primary visual driver.
        for d in 0...depthLimit {
            let alpha = alphaCache[min(d, maxDepth)]
            // Gradient from white to clock-colored
            let r = d == 0 ? 1.0 : (0.5 + 0.5 * pow(colorAdjustment, CGFloat(d)))
            let g = d == 0 ? 1.0 : pow(0.92, CGFloat(d))
            let b = d == 0 ? 1.0 : (0.1 + 0.9 * pow(colorAdjustment, CGFloat(d)))
            
            context.setStrokeColor(red: r, green: g, blue: b, alpha: alpha)
            context.addPath(depthPaths[d])
            context.strokePath()
        }
        
        accumulatedSeconds += (Date.timeIntervalSinceReferenceDate - startTime)
        accumulatedFrames += 1
    }
    
    private func buildPaths(origin: CGPoint, vector: CGSize, r0: Rotator, r1: Rotator, depth: Int, depthLeft: Int) {
        let p2 = CGPoint(x: origin.x + vector.width, y: origin.y + vector.height)
        
        // Prune
        let lengthSq = vector.width * vector.width + vector.height * vector.height
        if lengthSq < 0.25 { return }

        // Add to batch path
        let path = depthPaths[depth]
        if depth == 0 {
            path.move(to: CGPoint(x: origin.x + vector.width * 0.5, y: origin.y + vector.height * 0.5))
        } else {
            path.move(to: origin)
        }
        path.addLine(to: p2)

        if depthLeft >= 1 {
            let vectorLeft = rotateSize(rotator: r0, s0: vector)
            buildPaths(origin: p2, vector: vectorLeft, r0: r0, r1: r1, depth: depth + 1, depthLeft: depthLeft - 1)
            
            let vectorRight = rotateSize(rotator: r1, s0: vector)
            buildPaths(origin: p2, vector: vectorRight, r0: r0, r1: r1, depth: depth + 1, depthLeft: depthLeft - 1)
        }
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
