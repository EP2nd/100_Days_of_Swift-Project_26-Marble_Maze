//
//  GameScene.swift
//  Project26
//
//  Created by Edwin Przeźwiecki Jr. on 29/10/2022.
//

import CoreMotion
import GameplayKit
import SpriteKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    /// Challenge 3:
    case portal = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    /// Challenge 3:
    var exitPortal: SKSpriteNode!
    
    /// Hack for the possibility of testing in a simulator:
    var lastTouchPosition: CGPoint?
    
    var motionManager: CMMotionManager!
    
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    /// Challenge 2:
    var currentLevel = 1
    /// Challenge 3:
    var playersInitialPosition = CGPoint(x: 96, y: 672)
    
    var isGameOver = false
    
    override func didMove(to view: SKView) {
        /// Challenge 2:
        setEnvironment()
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        /// Challenge 2:
        loadLevel()
        createPlayer(playersInitialPosition)
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Hack for the possibility of testing in a simulator:
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Hack for the possibility of testing in a simulator:
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Hack for the possibility of testing in a simulator:
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        guard isGameOver == false else { return }
        
        /// Hack for the possibility of testing in a simulator:
        #if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition {
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    /// Challenge 2:
    func setEnvironment() {
        
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.name = "background"
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.name = "scoreLabel"
        scoreLabel.text = "Score: \(score)"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }
    
    func loadLevel() {
        /// Challenge 2:
        guard let levelURL = Bundle.main.url(forResource: "level\(currentLevel)", withExtension: "txt") else {
            fatalError("Could not find level scheme file in the app bundle.")
        }
        
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not find level scheme file in the app bundle.")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                switch letter {
                /// Challenge 1:
                case "x":
                    createBlock(position)
                case "v":
                    createVortex(position)
                case "s":
                    createStar(position)
                case "f":
                    createFinish(position)
                /// Challenge 3:
                case "i":
                    createEntryPortal(position)
                /// Challenge 3:
                case "o":
                    createExitPortal(position)
                case " ":
                    /// This is an empty space - do nothing.
                    continue
                default:
                    fatalError("Unknown level letter: \(letter)")
                }
                
                /* /// Challenge 1:
                if letter == "x" {
                    createBlock(position)
                } else if letter == "v" {
                    createVortex(position)
                } else if letter == "s" {
                    createStar(position)
                } else if letter == "f" {
                    createFinish(position)
                /// Challenge 3:
                } else if letter == "i" {
                    createEntryPortal(position)
                /// Challenge 3:
                } else if letter == "o" {
                    createExitPortal(position)
                } else if letter == " " {
                    /// This is an empty space - do nothing.
                } else {
                    fatalError("Unknown level letter: \(letter)")
                } */
                
            }
        }
    }
    
    /// Challenge 1:
    func createBlock(_ position: CGPoint) {
        
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        
        addChild(node)
    }
    
    func createVortex(_ position: CGPoint) {
        
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        addChild(node)
    }
    
    func createStar(_ position: CGPoint) {
        
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        node.position = position
        
        addChild(node)
    }
    
    func createFinish(_ position: CGPoint) {
        
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        node.position = position
        
        addChild(node)
    }
    /// Challenge 3:
    func createEntryPortal(_ position: CGPoint) {
        
        let node = SKSpriteNode(imageNamed: "portal")
        node.name = "entrance"
        
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 0.0001)))
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.portal.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        node.position = position
        
        addChild(node)
    }
    /// Challenge 3:
    func createExitPortal(_ position: CGPoint) {
        
        exitPortal = SKSpriteNode(imageNamed: "portal")
        exitPortal.name = "exit"
        
        exitPortal.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 0.0001)))
        
        exitPortal.physicsBody = SKPhysicsBody(circleOfRadius: exitPortal.size.width / 2)
        exitPortal.physicsBody?.isDynamic = false
        exitPortal.physicsBody?.categoryBitMask = CollisionTypes.portal.rawValue
        exitPortal.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        exitPortal.physicsBody?.collisionBitMask = 0
        
        exitPortal.position = position
        
        addChild(exitPortal)
    }
    
    func createPlayer(_ location: CGPoint) {
        
        player = SKSpriteNode(imageNamed: "player")
        
        player.position = location
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(by: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale ,remove])
            
            player.run(sequence) { [weak self] in
                self?.createPlayer(self!.playersInitialPosition)
                self?.isGameOver = false
            }
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
            /// Challenge 2:
            removeAllChildren()
            setEnvironment()
            currentLevel += 1
            loadLevel()
            createPlayer(playersInitialPosition)
        /// Challenge 3:
        } else if node.name == "entrance" {
            player.removeFromParent()
            createPlayer(exitPortal.position)
        }
    }
}
