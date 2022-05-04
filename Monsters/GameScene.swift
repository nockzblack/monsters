//
//  GameScene.swift
//  Monsters
//
//  Created by Fernando's Mac on 14/04/22.
//

import SpriteKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func lenght() -> CGFloat {
        return sqrt(x*x + y*y)
    }
}

func normalized() -> CGPoint {
    return self / length()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let monster: UInt32 = 0b1
        static let projectile: UInt32 = 0b10
    }
    
    let player = SKSpriteNode(imageNamed: "player")
    
    var monstersDesroyed = 0
    
    override func didMove(to view: SKView) {
        //Design
        
        backgroundColor = SKColor.green
        player.position = CGPoint (x: size.width * 0.3, y: size.height * 0.5)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence(
                [SKAction.run(addMonster),
                 SKAction.wait(forDuration: 1.0)]
                    )
        ))
        
    }
    
    func random() -> CGFloat {
        return CGFloat(arc4random() / 0xFFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        let monster = SKSpriteNode(imageNamed: "monster")
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        monster.physicsBody?.isDynamic = true
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        addChild(monster)
        
        // Speed:
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Actions:
        
        let actionMove = SKAction.move(to: CGPoint(x:-monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        
        let actionMoveDone = SKAction.removeFromParent()
        
        let loseAction = SKAction.run() { [weak self] in
            guard let `self` = self else { return }
        }
        
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        
        let gameOver = GameOverScene(size: self.size, won: false)
        
        self.view?.presentScene(gameOver, transition: reveal)
        
        monster.run(SKAction.sequence([
            actionMove, loseAction, actionMoveDone
        ]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first {
            return
        }
        
        let touchesLocation = touch.location(in: self)
        
        let projectile = SKSpriteNode(imageNamed: "projectile")
        
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        // Location from toouch to projectile
        
        let offset = touchesLocation - projectile.position
        
        // Shooting?
        
        if offset.x < 0 {
            return
        }
        
        addChild(projectile)
        
        // Direction of shooting
        
        let direction = offset.normalized()
        
        let shootAmount = direction * 1000
        
        let realDest = shootAmount + projectile.position
        
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        
        let actionMoveDone = SKAction.removeFromParent()
        
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Collinction")
        
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDesroyed += 1
        
        if monstersDesroyed > 10 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            let gameOverScene = GameOverScene(size: self.size, won: true)
            
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
}


extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
    }
}

