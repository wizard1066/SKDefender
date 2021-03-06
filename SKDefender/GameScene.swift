//
//  GameScene.swift
//  SKDefender
//
//  Created by localadmin on 06.11.18.
//  Copyright © 2018 ch.cqd.skdefender. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCat {
    static let None: UInt32 = 0
    static let Player: UInt32 = 0b1
    static let Ground: UInt32 = 0b1 << 1
    static let Fire: UInt32 = 0b1 << 2
    static let SpaceMan: UInt32 = 0b1 << 3
    static let Alien: UInt32 = 0b1 << 4
}

class GameScene: SKScene, SKPhysicsContactDelegate, touchMe {
    
    var moveLeft = false
    var moveRight = false
    
    enum Layer: CGFloat {
        case background
        case foreground
        case player
        case spaceman
        case alien
    }
    
    let player = PlayerEntity(imageName: "starship")
    var alien:AlienEntity!
    var hud: SKNode!
    
    var playableStart: CGFloat = 0
    
    var deltaTime: TimeInterval = 0
    var lastUpdateTimeInterval: TimeInterval = 0
    
    let numberOfForegrounds = 6
    var groundSpeed:Double = 150
    var brakeSpeed:Double = 0.1
    var cameraScale:CGFloat = 1
    var cameraMove = 512
    
    lazy var screenWidth = view!.bounds.width
    lazy var screenHeight = view!.bounds.height
    
    func buildGround(color: UIColor) -> (SKTexture, CGMutablePath) {
        let loopsNeeded = Int(screenWidth / 120)
        var path: CGMutablePath?
        var lastValue = 96
        for loop in stride(from: 0, to: Int(screenWidth*2), by: loopsNeeded) {
            let randomSource = GKARC4RandomSource()
            let randomDistribution = GKRandomDistribution(randomSource: randomSource, lowestValue: 80, highestValue: 128)
            let randomValueY = randomDistribution.nextInt()
            if path == nil {
                path = CGMutablePath()
                path!.move(to: CGPoint(x: 0, y: lastValue))
            } else {
                path!.addLine(to: CGPoint(x: loop, y: randomValueY))
            }
            if loop + loopsNeeded > Int(screenWidth*2) {
                lastValue = randomValueY
            }
        }
        
        let shape = SKShapeNode()
        shape.path = path
        shape.strokeColor = color
        shape.lineWidth = 2
        shape.zPosition = 1
        
        let texture = view?.texture(from: shape)
        return (texture!,path!)
    }
    
    var aliens:[GKEntity] = []
    var foregrounds:[EntityNode] = []
    var colours = [UIColor.red, UIColor.white, UIColor.green, UIColor.yellow, UIColor.purple, UIColor.blue, UIColor.magenta, UIColor.orange, UIColor.cyan]
    
    func setupForeground() {
        
        for i in 0..<numberOfForegrounds {
            let color2U = colours[i]
            let (texture, path) = buildGround(color: color2U)
            let foreground = BuildEntity(texture: texture, path: path, i: i)
            let foregroundNode = foreground.buildComponent.node
            foregroundNode.delegate = self
            addChild(foregroundNode)
            foregrounds.append(foregroundNode)
            // restructure
        }
        for loop in 0..<numberOfForegrounds {
            let randomSource = GKARC4RandomSource()
            let randomDistribution = GKRandomDistribution(randomSource: randomSource, lowestValue: 0, highestValue: 4)
            let randomValueT = Double(randomDistribution.nextInt())
            let waitAction = SKAction.wait(forDuration: randomValueT)
            let runAction = SKAction.run {
                self.addSpaceMen(loop: loop)
            }
            foregrounds[loop].run(SKAction.sequence([waitAction,runAction]))
        }
    }
    
    func addSpaceMen(loop: Int) {
        let randomSource = GKARC4RandomSource()
        let randomDistribution = GKRandomDistribution(randomSource: randomSource, lowestValue: 0, highestValue: Int(self.view!.bounds.width))
        let randomValueX = CGFloat(randomDistribution.nextInt())
        
        let spaceMan = RescueEntity(imageName: "spaceMan", xCord: view!.bounds.maxX + randomValueX, yCord:view!.bounds.minY + 96)
        let spaceNode = spaceMan.rescueComponent.node
        spaceNode.delegate = self
        spaceNode.zPosition = Layer.spaceman.rawValue
        if spaceNode.parent == nil {
            //                    foregroundNode.addChild(spaceNode)
            foregrounds[loop].addChild(spaceNode)
        }
        
        let alien = AlienEntity(imageName: "alien",xCord: view!.bounds.maxX + randomValueX, yCord:self.view!.bounds.maxY)
        let alienNode = alien.spriteComponent.node
        let procedure = alien.alienComponent
        alienNode.userData!["procedure"] = procedure
        alienNode.zPosition = Layer.alien.rawValue
        alienNode.delegate = self
        if alienNode.parent == nil {
            //                    foregroundNode.addChild(alienNode)
            foregrounds[loop].addChild(alienNode)
        }
        aliens.append(alien)
    }
    
    var moveAmount: CGPoint!
    var foregroundCGPoint: CGFloat!
   
    
    
//    func updateForegroundLeft() {
//        self.enumerateChildNodes(withName: "foreground") { (node, stop) in
//            if let foreground = node as? SKSpriteNode {
//                self.moveAmount = CGPoint(x: -CGFloat(self.groundSpeed) * CGFloat(self.deltaTime), y: self.playableStart)
//                foreground.position.x += self.moveAmount.x
//                self.foregroundCGPoint = foreground.position.x
//
//                if foreground.position.x < -foreground.size.width {
//                    foreground.position.x += foreground.size.width * CGFloat(self.numberOfForegrounds)
//                }
//            }
//        }
//    }
    
    func updateForegroundLeft() {
        playerNode.physicsBody?.applyForce(CGVector(dx: 48, dy: 0))
        for foreground in foregrounds {
            let dx = foreground.position.x - cameraNode.position.x
            if dx < -(foreground.size.width * CGFloat(numberOfForegrounds/2) + size.width / 2) {
                foreground.position.x += foreground.size.width * CGFloat(numberOfForegrounds)
                print("switch left")
            }
        }
    }
    
    // fucked
    
    func updateForegroundRight() {
        playerNode.physicsBody?.applyForce(CGVector(dx: -48, dy: 0))
        for foreground in foregrounds {
            let zx = foreground.size.width + cameraNode.position.x
            if zx < foreground.position.x {
                foreground.position.x -= foreground.size.width * CGFloat(numberOfForegrounds)
                print("switch right")
            }
        }
    }
    
//    func updateForegroundRight() {
//        self.enumerateChildNodes(withName: "foreground") { (node, stop) in
//            if let foreground = node as? SKSpriteNode {
//                self.moveAmount = CGPoint(x: -CGFloat(self.groundSpeed) * CGFloat(self.deltaTime), y: self.playableStart)
//                foreground.position.x -= self.moveAmount.x
//                self.foregroundCGPoint = foreground.position.x
//
//                if foreground.position.x > foreground.size.width {
//                    foreground.position.x -= foreground.size.width * CGFloat(self.numberOfForegrounds)
//                }
//            }
//        }
//    }
    
    
    
    var playerNode: EntityNode!
//    var advanceArrow: TouchableSprite!
    var advancedArrow: HeadsUpEntity!
    var zoomButton: HeadsUpEntity!
    
    func setupPlayer(){
        playerNode = player.spriteComponent.node
        playerNode.position = CGPoint(x: self.view!.bounds.maxX / 2, y: self.view!.bounds.maxY / 2)
        playerNode.zPosition = Layer.player.rawValue
//        playerNode.size = CGSize(width: playerNode.size.width/4, height: playerNode.size.height/4)
        playerNode.delegate = self
        addChild(playerNode)
        
        
//        player.movementComponent.playableStart = playableStart
        
        let upArrow = HeadsUpEntity(imageName: "UpArrow", xCord: (self.view?.bounds.minX)! + 128, yCord: ((self.view?.bounds.maxY)!) + 96, name: "up")
        upArrow.hudComponent.node.delegate = self

        let downArrow = HeadsUpEntity(imageName: "DownArrow", xCord: (self.view?.bounds.minX)! + 128, yCord: ((self.view?.bounds.maxY)!) - 96, name: "down")
        downArrow.hudComponent.node.delegate = self
        
        advancedArrow = HeadsUpEntity(imageName: "RightArrow", xCord: ((self.view?.bounds.maxX)!) - 128, yCord: ((self.view?.bounds.maxY)!) - 96, name: "advance")
        advancedArrow.hudComponent.node.delegate = self
        
        let stopSquare = HeadsUpEntity(imageName: "Square", xCord: (self.view?.bounds.minX)! + 128, yCord: ((self.view?.bounds.maxY)!), name: "square")
        stopSquare.hudComponent.node.delegate = self
        
//        let fireSquare = HeadsUpEntity(imageName: "Square", xCord: ((self.view?.bounds.maxX)! * 2) - 128, yCord: ((self.view?.bounds.maxY)!), name: "fire")
        let fireSquare = HeadsUpEntity(imageName: "Square", xCord: ((self.view?.bounds.maxX)!) - 128, yCord: ((self.view?.bounds.maxY)!), name: "fire")
        fireSquare.hudComponent.node.delegate = self
        
        let flipButton = HeadsUpEntity(imageName: "SwiftLogo", xCord: ((self.view?.bounds.maxX)!) - 128, yCord: ((self.view?.bounds.maxY)!) + 96, name: "flip")
        flipButton.hudComponent.node.delegate = self
        
        hud = SKNode()
        hud.position = CGPoint(x: -(self.view?.bounds.maxX)!, y: -(self.view?.bounds.maxY)! / 2)
        playerNode.addChild(hud)
        
        
        hud.addChild(upArrow.hudComponent.node)
        hud.addChild(downArrow.hudComponent.node)
        hud.addChild(stopSquare.hudComponent.node)
        hud.addChild(advancedArrow.hudComponent.node)

        hud.addChild(fireSquare.hudComponent.node)
        hud.addChild(flipButton.hudComponent.node)
        
        zoomButton = HeadsUpEntity(imageName: "Zoom", xCord: 0, yCord: self.view!.bounds.maxY - 128, name: "zoom")
        zoomButton.hudComponent.node.delegate = self
        
        hud.addChild(zoomButton.hudComponent.node)
        
        
    }
    
    var cameraNode: SKCameraNode!
    var cameraNode2: SKCameraNode!
    var subWin: SKScene!
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.5)
        physicsWorld.contactDelegate = self
        
        cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: self.view!.bounds.maxX, y: self.view!.bounds.maxY)
        scene?.camera = cameraNode

        cameraNode.setScale(1)

        addChild(cameraNode)
        
        setupForeground()
        setupPlayer()
        cameraNode.position = CGPoint(x: self.view!.bounds.maxX, y: self.view!.bounds.maxY)
        
        
//        Add a boundry to the screen
        let rectToSecure = CGRect(x: 0, y: 0, width: self.view!.bounds.maxX * 2, height: self.view!.bounds.minX * 2)
        physicsBody = SKPhysicsBody(edgeLoopFrom: rectToSecure)
        physicsBody?.isDynamic = false

        
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if lastUpdateTimeInterval == 0 {
            lastUpdateTimeInterval = currentTime
        }
        
        deltaTime = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime
        
        if moveLeft {
            updateForegroundLeft()
            lowerSpeed()
        }
        if moveRight {
            updateForegroundRight()
            lowerSpeed()
        }
        player.update(deltaTime: deltaTime)
        for alien in aliens {
            alien.update(deltaTime: deltaTime)
        }
        
        camera?.position.x = playerNode.position.x
        
    }
    
    func lowerSpeed() {
        if groundSpeed > 24 {
            groundSpeed = groundSpeed - brakeSpeed
        } else {
            groundSpeed = 24
        }
    }
    
    func moreBreak() {
        brakeSpeed = brakeSpeed * 2
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let pointTouched = touches.first?.location(in: self.view)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let pointTouched = touches.first?.location(in: self.view)
        
        if pointTouched!.x < (self.view?.bounds.minX)! + 128, pointTouched!.y < ((self.view?.bounds.midY)!){
            player.movementComponent.applyImpulseUp(lastUpdateTimeInterval)
            return
        }
        if pointTouched!.x < (self.view?.bounds.minX)! + 128, pointTouched!.y > ((self.view?.bounds.midY)!){
            player.movementComponent.applyImpulseDown(lastUpdateTimeInterval)
            return
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("ended")
    }
    
//    var pickup: CGPoint!
    
    var playerCG: CGFloat!
    
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCat.Player ? contact.bodyB : contact.bodyA
        let kidnap = contact.bodyA.categoryBitMask == PhysicsCat.Alien ? contact.bodyB : contact.bodyA
        let hit = contact.bodyA.categoryBitMask == PhysicsCat.Fire ? contact.bodyB : contact.bodyA
        
        // alien kidnaps spaceman

        if kidnap.node?.name == "spaceman" && kidnap.node?.parent?.name == "foreground" && contact.bodyB.node!.name == "alien" {
            print("rule I")
//            pickup = other.node?.position
            
            kidnap.node?.removeFromParent()
            kidnap.node?.position = CGPoint(x: 0, y: -96)
            contact.bodyB.node?.addChild(kidnap.node!)
//            self.alien.alienComponent.changeDirection(self.lastUpdateTimeInterval)
//            let execute = contact.bodyB.node?.userData!["procedure"] as? AlienDecentComponent
//            execute?.stopSpaceMan()
//            contact.bodyB.node?.run(SKAction.move(to: CGPoint(x: (contact.bodyB.node?.position.x)!, y: 512), duration: 4))
            //restructure
            return
        }
        
        // drop spaceman if ground touches him
        
        if other.node?.name == "spaceman" && other.node?.parent?.name == "foreground" && contact.bodyB.node!.name == "starship" {
//        if other.node?.name == "spaceman" && contact.bodyB.node!.name == "starship" {
            print("rule II")
//            pickup = other.node?.position
            other.node?.removeFromParent()
            other.node?.position = CGPoint(x: 0, y: -96)
            other.node?.physicsBody?.isDynamic = false
            contact.bodyB.node?.addChild(other.node!)
            return
        }
        
        // drop spaceman if ground touches him while carried by starship
        
        if other.node?.name == "foreground" && contact.bodyB.node?.name == "starship"{
            print("rule III")
            let saving = contact.bodyB.node?.childNode(withName: "spaceman")
            if saving != nil {
//                saving?.position = (other.node?.position)!
                saving?.position.x = self.playerNode.position.x - (other.node?.position.x)!
                saving?.position.y = 96
                saving?.removeFromParent()
                other.node?.addChild(saving!)
            }
            return
        }
        
        // alien hit, releases spaceman

        if hit.node?.name == "alien" {
            print("rule IV bodyA \(contact.bodyA.node!.name) bodyB \(contact.bodyB.node!.name)")
            let victim = hit.node?.childNode(withName: "spaceman")
            contact.bodyA.node?.removeFromParent()
            
            let parent2U = hit.node?.parent
            hit.node?.removeFromParent()
            if victim != nil {
                victim?.position = (hit.node?.position)!
                victim?.removeFromParent()
                victim?.physicsBody?.isDynamic = true
                parent2U?.addChild(victim!)
            }
            return
        }
        
        // spaceman falling to ground
        
        if other.node?.name == "foreground" {
            print("rule V")
            contact.bodyB.node?.physicsBody?.isDynamic = false
            let poc = CGPoint(x: (contact.bodyB.node?.position.x)!, y: 96)
            contact.bodyB.node?.run(SKAction.move(to: poc, duration: 0.5))
            return
        }
        
        // shoot the spaceman and he will disppear
        
        if hit.node?.name == "spaceman" && contact.bodyB.node?.name != "starship" {
            print("rule VI \(contact.bodyB.node?.name)")
            hit.node?.removeFromParent()
        }
    }
    
    var previousDirection:String?
    
    func spriteTouched(box: TouchableSprite) {
        switch box.name {
        case "starship":
            print("cameraNode fucked \(playerNode.position)")
        case "spaceman":
            print("cords \(box.position) \(moveAmount)")
        case "up":
//            let dontMove = hud.convert(position, to: playerNode)

//            player.movementComponent.applyImpulseUp(lastUpdateTimeInterval)
            playerNode.run(SKAction.move(by: CGVector(dx: 0, dy: 136), duration: 0.5))
            hud.run(SKAction.move(by: CGVector(dx: 0, dy: -136), duration: 0))

//            hud.position = dontMove
        case "down":
//            let dontMove = hud.convert(position, to: playerNode)
//            player.movementComponent.applyImpulseDown(lastUpdateTimeInterval)
            playerNode.run(SKAction.move(by: CGVector(dx: 0, dy: -136), duration: 0.5))
            hud.run(SKAction.move(by: CGVector(dx: 0, dy: 136), duration: 0))
//            hud.position = dontMove
        case "advance":
            let direct = playerNode.userData?.object(forKey: "direction") as? String
            if previousDirection == nil || previousDirection != direct {
                groundSpeed = 150
                brakeSpeed = 0.1
                previousDirection = direct
            } else {
                groundSpeed += 30
                previousDirection = direct
            }
            switch direct {
            case "left":
                moveRight = true
                moveLeft = false
//                player.movementComponent.applyImpulseX(lastUpdateTimeInterval)
                cameraMove = -512
            case "right":
                moveRight = false
                moveLeft = true
//                player.movementComponent.applyImpulseX(lastUpdateTimeInterval)
                cameraMove = 512
            default:
                break
            }
        //                player.movementComponent.applyImpulseLeft(lastUpdateTimeInterval)
        case "flip":
            let direct = playerNode.userData?.object(forKey: "direction") as? String
            groundSpeed = 150
            brakeSpeed = 0.1
            switch direct {
            case "left":
                advancedArrow.hudComponent.changeTexture(imageNamed: "RightArrow")
                // moveRight/moveLet control the background direction
                moveLeft = true
                moveRight = false
                player.movementComponent.applyImpulseLeft(lastUpdateTimeInterval)
//                cameraMove = 512
//                cameraNode.run(SKAction.move(by: CGVector(dx: 512, dy: 0), duration: 2))
            case "right":
                advancedArrow.hudComponent.changeTexture(imageNamed: "LeftArrow")
                moveRight = true
                moveLeft = false
                player.movementComponent.applyImpulseRight(lastUpdateTimeInterval)
//                cameraMove = -512
//                cameraNode.run(SKAction.move(by: CGVector(dx: -512, dy: 0), duration: 2))
            default:
                break
            }
        case "fire":
            let mshape = CGRect(x: 0, y: 0, width: 24, height: 6)
            let missileX = FireEntity(rect: mshape, xCord: 0, yCord: 0)
            
            let fireNode = missileX.shapeComponent.node
            fireNode.zPosition = Layer.alien.rawValue
            playerNode.addChild(fireNode)
            
            let direct = playerNode.userData?.object(forKey: "direction") as? String
            switch direct {
            case "left":
                missileX.pathComponent.releaseFireLeft(lastUpdateTimeInterval)
            case "right":
                missileX.pathComponent.releaseFireRight(lastUpdateTimeInterval)
            default:
                break
            }
        case "zoom":
            cameraScale += 1
            
            if cameraScale > 4 {
                let calc:CGFloat = (((1/2)/3)/4)
                cameraNode.run(SKAction.scale(by: calc, duration: 2))
                zoomButton.hudComponent.node.run(SKAction.scale(by: calc, duration: 2))
                cameraScale = 1
            } else {
                
                cameraNode.run(SKAction.scale(by: cameraScale, duration: 2))
                zoomButton.hudComponent.node.run(SKAction.scale(by: cameraScale, duration: 2))
            }
            print("camera Scale \(cameraScale)")
        
            
        default:
            moreBreak()
        }
    }
}

public extension CGFloat {
    public func degreesToRadians() -> CGFloat {
        return CGFloat.pi * self / 180.0
    }

    public func radiansToDegrees() -> CGFloat {
        return self * 180.0 / CGFloat.pi
    }
}
