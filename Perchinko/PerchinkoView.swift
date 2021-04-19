//
//  PerchinkoView.swift
//  Perchinko
//
//  Created by Steve Sparks on 4/13/21.
//

import UIKit
import AVFoundation

class BoundaryIdentifier: NSObject, NSCopying {
    var name: String = "boundary"
    var value: Int = 1
    
    init(_ name: String, _ value: Int) {
        self.name = name
        self.value = value
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return BoundaryIdentifier(name, value)
    }
}

class PerchinkoView: UIView {
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var _animator: UIDynamicAnimator?
    var animator: UIDynamicAnimator {
        set {
            _animator = newValue
        }
        get {
            if let anim = _animator {
                return anim
            } else {
                let anim = UIDynamicAnimator(referenceView: self)
                _animator = anim
                return anim
            }
        }
    }
    
    let scoreLabel = UILabel()
    
    let gravity = UIGravityBehavior()
    let collider = UICollisionBehavior()
    let pointCounter = UICollisionBehavior()
    
    let pinBehavior: UIDynamicItemBehavior = {
        let beh = UIDynamicItemBehavior()
        beh.isAnchored = true
        beh.allowsRotation = true
        beh.elasticity = 1.0
        return beh
    }()
    
    let ballBehavior: UIDynamicItemBehavior = {
        let beh = UIDynamicItemBehavior()
        beh.density = 0.4
        beh.friction = 0.0
        beh.allowsRotation = true
        beh.angularResistance = 0.0
        beh.resistance = 0.0
        beh.elasticity = 0.8
        return beh
    }()
    var pins = [UIView]()
    var balls = [UIView]()
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        animator.removeAllBehaviors()
        for v in subviews {
            v.removeFromSuperview()
        }
        pointCounter.collisionDelegate = self
        pointCounter.collisionMode = .boundaries
        animator.addBehavior(pointCounter)
        
        balls.removeAll()
        pins.removeAll()
        
        addSubview(scoreLabel)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scoreLabel.textColor = .black
        scoreLabel.font = .boldSystemFont(ofSize: 14.0)
        score = 0
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print("WEE")
        
        if superview != nil {
            setupBoard()
        }
    }
    
    func setupBoard() {
        animator.addBehavior(gravity)
        animator.addBehavior(collider)
        animator.addBehavior(pinBehavior)
        collider.translatesReferenceBoundsIntoBoundary = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(nudge(_:)))
        self.addGestureRecognizer(tap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(reset(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)

        gravity.gravityDirection = CGVector(dx: 0, dy: 0.8)
        
        addPins()
        addBalls()
        addBars()
    }
    
    func addBars() {
        let offsets = oddRowOffsets
        let y = CGFloat(435.0)

        
        let left = CGPoint(x: offsets[2], y: y)
        let center1 = CGPoint(x: offsets[3], y: y)
        let center2 = CGPoint(x: offsets[4], y: y)
        let right = CGPoint(x: offsets[5], y: y)

        
        pointCounter.addBoundary(withIdentifier: BoundaryIdentifier("left", 1), from: left, to: center1)
        pointCounter.addBoundary(withIdentifier: BoundaryIdentifier("center", 2), from: center1, to: center2)
        pointCounter.addBoundary(withIdentifier: BoundaryIdentifier("right", 1), from: center2, to: right)
    }

    var oddRowOffsets: [CGFloat] {
        let width = max(bounds.size.width, 10.0)
        let xWidth = (width / 10.0)
        let half = xWidth / 2.0
        return Array(1...8).map { half + CGFloat($0) * xWidth }
    }

    var evenRowOffsets: [CGFloat] {
        let width = max(bounds.size.width, 10.0)
        let xWidth = (width / 10.0)

        return Array(1...9).map { CGFloat($0) * xWidth }
    }

    func addPins(_ numberOfPins: Int = 30) {
        for pin in pins {
            pin.removeFromSuperview()
        }
        pins = []
        
        for y in [20, 40, 60, 80, 100] {
            for x in evenRowOffsets {
                let point = CGPoint(x: x, y: 30.0 + CGFloat(y) * 3.5)
                addPinAt(point)
            }
        }

        for y in [30, 50, 70, 90, 110] {
            for x in oddRowOffsets {
                let point = CGPoint(x: x, y: 30.0 + CGFloat(y) * 3.5)
                addPinAt(point)
            }
        }
    }

    @discardableResult
    func addBallAt(_ point: CGPoint, diameter: CGFloat = 14.0) -> UIView {
        let radius = diameter / 2
        let frame = CGRect(x: point.x - radius, y: point.y + radius, width: diameter, height: diameter)
        let view = BallView(frame: frame)
        view.layer.cornerRadius = radius
        view.backgroundColor = .green
        addSubview(view)
        balls.append(view)
        gravity.addItem(view)
        collider.addItem(view)
        pointCounter.addItem(view)
        
        return view
    }
    
    @discardableResult
    func addPinAt(_ point: CGPoint, diameter: CGFloat = 5.0) -> UIView {
        let radius = diameter / 2
        let frame = CGRect(x: point.x - radius, y: point.y + radius, width: diameter, height: diameter)
        let view = PinView(frame: frame)
        view.layer.cornerRadius = radius
        view.backgroundColor = .black
        addSubview(view)
        pins.append(view)
        collider.addItem(view)
        pinBehavior.addItem(view)
        return view
    }
    
    func addBalls(_ numberOfBalls: Int = 60) {
        for ball in balls {
            ball.removeFromSuperview()
        }
        balls = []

        let width = self.bounds.size.width

        for x in 1...numberOfBalls {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(x) * 0.1)) {
                let rX = width / 4 + fmod(CGFloat(arc4random()), max(width / 2, 4.0))
                let rY = fmod(CGFloat(arc4random()), min(max(self.bounds.size.height, 4.0), 100))
                let ball = self.addBallAt(CGPoint(x: rX, y: rY))
                ball.tag = x
            }
        }
    }
    
    @objc @IBAction func reset(_ sender: Any?) {
        balls.forEach {
            collider.removeItem($0)
            pointCounter.removeItem($0)
            ballBehavior.removeItem($0)
            gravity.removeItem($0)
            $0.removeFromSuperview()
        }
        balls = []
        
        addBalls()
    }
    
    @objc @IBAction func nudge(_ sender: Any?) {
        let push = UIPushBehavior(items: balls, mode: .instantaneous)
        push.angle = ((5000 + CGFloat(arc4random() % 10000) / 10000) - .pi) / 2.0
        push.magnitude = 0.01
        animator.addBehavior(push)
    }
}


class PinView: UIView {
    override var collisionBoundingPath: UIBezierPath {
        return UIBezierPath(cgPath: CGPath(ellipseIn: self.bounds, transform: nil))
    }
}


class HoleView: UIView {
    var value = 1
    
    override var collisionBoundingPath: UIBezierPath {
        return UIBezierPath(cgPath: CGPath(ellipseIn: self.bounds, transform: nil))
    }
}

class BallView: UIImageView {
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        image = UIImage(named: "pinball")
    }
    
    override var collisionBoundingPath: UIBezierPath {
        return UIBezierPath(cgPath: CGPath(ellipseIn: self.bounds, transform: nil))
    }
}

extension PerchinkoView: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        guard let ball = item as? BallView else {
            print("bold")
            return
        }
        guard let ident = identifier as? BoundaryIdentifier else {
            print("weird")
            return
        }
        self.collider.removeItem(ball)
        self.pointCounter.removeItem(ball)
        self.gravity.removeItem(ball)
        self.ballBehavior.removeItem(ball)

        score += ident.value

        if let idx = balls.firstIndex(of: ball) {
            balls.remove(at: idx)
        }
        
//        AudioServicesPlaySystemSound(1016)
        ball.transform = .identity
        UIView.animate(withDuration: 0.5, animations: {
            ball.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            ball.removeFromSuperview()
        })
    }
}
