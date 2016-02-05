//
//  ViewController.swift
//  SpriteKitMotionBlur
//
//  Created by Simon Gladman on 05/02/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit

import UIKit
import SpriteKit

class ViewController: UIViewController, SKSceneDelegate
{
    let modeSegmentedControl = UISegmentedControl(items: [Mode.MotionBlur.rawValue, Mode.MetaBalls.rawValue])
    
    let skView = SKView()
    let scene = SKScene()

    let radialGravity = SKFieldNode.radialGravityField()
    
    let ballColors = [UIColor.redColor(),
        UIColor.greenColor(),
        UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0),
        UIColor.cyanColor(),
        UIColor.magentaColor(),
        UIColor.yellowColor()]
    
    var mode: Mode = .MotionBlur
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        scene.scaleMode = .ResizeFill
        skView.presentScene(scene)
        
        skView.backgroundColor = UIColor.grayColor()
        view.addSubview(skView)
        
        for i in 0 ... 50
        {
            let ball = MotionBlurredBall()

            ball.position = CGPoint(
                x: CGFloat(drand48()) * view.frame.width,
                y: CGFloat(drand48()) * view.frame.height)
            
            ball.color = ballColors[i % ballColors.count]
 
            scene.addChild(ball)
        }
        
        radialGravity.strength = 0
        scene.addChild(radialGravity)
        
        createWalls()

        scene.delegate = self
        
        // ---
        
        view.addSubview(modeSegmentedControl)
        
        modeSegmentedControl.selectedSegmentIndex = 0
        
        modeSegmentedControl.addTarget(self,
            action: "modeChangeHandler",
            forControlEvents: .ValueChanged)
    }

    // MARK: SceneKit
    
    func update(currentTime: NSTimeInterval, forScene scene: SKScene)
    {
        for node in scene.children where node is MotionBlurredBall
        {
            if mode == .MotionBlur
            {
                (node as! MotionBlurredBall).updateMotionBlur()
            }
            else
            {
                (node as! MotionBlurredBall).shouldEnableEffects = false
            }
        }
    }
    
    
    func setGravityFromTouch(touch: UITouch)
    {
        radialGravity.falloff = 0.5
        radialGravity.region = SKRegion(radius: 200)
        
        radialGravity.strength = (traitCollection.forceTouchCapability == UIForceTouchCapability.Available) ?
            Float(touch.force / touch.maximumPossibleForce) * 80 :
            40
        
        radialGravity.position = CGPoint(x: touch.locationInView(skView).x,
            y: view.frame.height - touch.locationInView(skView).y)
    }
    
    // MARK: User gesture handling
    
    func modeChangeHandler()
    {
        if let
            modeName = modeSegmentedControl.titleForSegmentAtIndex(modeSegmentedControl.selectedSegmentIndex),
            mode = Mode(rawValue: modeName)
        {
            self.mode = mode
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first else
        {
            return;
        }
        
        setGravityFromTouch(touch)
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first else
        {
            return;
        }
        
        setGravityFromTouch(touch)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        radialGravity.strength = 0
    }
    
    // MARK: Layout
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.Landscape
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    
    override func viewDidLayoutSubviews()
    {
        skView.frame = view.frame
        
        modeSegmentedControl.frame = CGRect(x: 0,
            y: 0,
            width: view.frame.width,
            height: modeSegmentedControl.intrinsicContentSize().height)
    }
    
    func createWalls()
    {
        let leftWall = SKShapeNode(rectOfSize: CGSize(width: 2, height: view.frame.height))
        leftWall.position = CGPoint(x: -2, y: view.frame.height / 2)
        leftWall.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 2, height: view.frame.height))
        leftWall.physicsBody?.dynamic = false
        leftWall.physicsBody?.restitution = 0
        leftWall.hidden = true
        scene.addChild(leftWall)
        
        let rightWall = SKShapeNode(rectOfSize: CGSize(width: 2, height: view.frame.height))
        rightWall.position = CGPoint(x: view.frame.width + 2, y: view.frame.height / 2)
        rightWall.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 2, height: view.frame.height))
        rightWall.physicsBody?.dynamic = false
        rightWall.physicsBody?.restitution = 0
        rightWall.hidden = true
        scene.addChild(rightWall)
        
        let floor = SKShapeNode(rectOfSize: CGSize(width: view.frame.width, height: 2))
        floor.position = CGPoint(x: view.frame.width / 2, y: -2)
        floor.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: view.frame.width, height: 2))
        floor.physicsBody?.dynamic = false
        floor.physicsBody?.restitution = 0
        floor.hidden = true
        scene.addChild(floor)

        let ceiling = SKShapeNode(rectOfSize: CGSize(width: view.frame.width, height: 2))
        ceiling.position = CGPoint(x: view.frame.width / 2, y: view.frame.height - 2)
        ceiling.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: view.frame.width, height: 2))
        ceiling.physicsBody?.dynamic = false
        ceiling.physicsBody?.restitution = 0
        ceiling.hidden = true
        scene.addChild(ceiling)
        
    }
    
}

enum Mode: String
{
    case MotionBlur = "Motion Blur"
    case MetaBalls = "Metaballs"
}

class MotionBlurredBall: SKEffectNode
{
    let ball = SKShapeNode(circleOfRadius: 30)
    let blur = CIFilter(name: "CIMotionBlur")!
    
    var color: UIColor = UIColor.blackColor()
    {
        didSet
        {
            ball.fillColor = color
            ball.strokeColor = color
        }
    }
    
    override init()
    {
        super.init()
        
        let ballPhysicsBody = SKPhysicsBody(polygonFromPath: ball.path!)
        ballPhysicsBody.restitution = 0.5
        ball.physicsBody = ballPhysicsBody
        
        addChild(ball)
        
        filter = blur
    }

    func updateMotionBlur()
    {
        if let ballPhysicsBody = ball.physicsBody
        {
            let angle = atan2(ballPhysicsBody.velocity.dy, ballPhysicsBody.velocity.dx)
            let velocity = sqrt(pow(ballPhysicsBody.velocity.dx, 2) + pow(ballPhysicsBody.velocity.dy, 2)) * 0.1
            
            blur.setValue(angle, forKey: kCIInputAngleKey)
            blur.setValue(velocity, forKey: kCIInputRadiusKey)
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

