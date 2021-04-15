//
//  PerchinkoView.swift
//  Perchinko
//
//  Created by Steve Sparks on 4/13/21.
//

import UIKit

class PerchinkoView: UIView {
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
    
    let gravity = UIGravityBehavior()
    let collider = UICollisionBehavior()
    
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
        balls.removeAll()
        pins.removeAll()
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
    }
    
    func addPins(_ numberOfPins: Int = 30) {
        for pin in pins {
            pin.removeFromSuperview()
        }
        pins = []

        // odd rows

        let width = max(bounds.size.width, 10.0)
        let xWidth = (width / 10.0)
        
        for y in [20, 40, 60, 80, 100, 120] {
            for x in 2...8 {
                let point = CGPoint(x: CGFloat(x) * xWidth, y: 30.0 + CGFloat(y) * 3.5)
                let pin = addPinAt(point)
                pin.tag = x
            }
        }

        for y in [30, 50, 70, 90, 110, 130] {
            for x in 1...8 {
                let point = CGPoint(x: (xWidth/2) + CGFloat(x) * xWidth, y: 30.0 + CGFloat(y) * 3.5)
                let pin = addPinAt(point)
                pin.tag = x
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

        for x in 1...numberOfBalls {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(x) * 0.1)) {
                let rX = fmod(CGFloat(arc4random()), max(self.bounds.size.width, 4.0))
                let rY = fmod(CGFloat(arc4random()), min(max(self.bounds.size.height, 4.0), 100))
                let ball = self.addBallAt(CGPoint(x: rX, y: rY))
                ball.tag = x
            }
        }
    }
    
    @objc @IBAction func reset(_ sender: Any?) {
        balls.forEach { $0.removeFromSuperview() }
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

class BallView: UIImageView {
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        image = UIImage(named: "pinball")
    }
    override var collisionBoundingPath: UIBezierPath {
        return UIBezierPath(cgPath: CGPath(ellipseIn: self.bounds, transform: nil))
    }
}
