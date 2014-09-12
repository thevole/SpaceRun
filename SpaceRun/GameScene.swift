//
//  GameScene.swift
//  SpaceRun
//
//  Created by Martin Volerich on 9/11/14.
//  Copyright (c) 2014 Bill Bear. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  
  weak var shipTouch: UITouch?
  
  var lastUpdateTime: NSTimeInterval?
  var lastShotFireTime: NSTimeInterval?
  var shipFireRate: CGFloat
  
  var shootSound: SKAction?
  var shipExplodeSound: SKAction?
  var obstacleExplodeSound: SKAction?
  
  var shipExplodeTemplate: SKEmitterNode?
  var obstacleExplodeTemplate: SKEmitterNode?
  
  
  required init(coder aDecoder: NSCoder) {
    shipFireRate = 0.5
    super.init(coder: aDecoder)
    
    backgroundColor = SKColor.blackColor()
    
    let starField = StarField.node()
    addChild(starField)
    
    let name = "Spaceship.png"
    let ship = SKSpriteNode(imageNamed: name)
    let size = self.size
    ship.position = CGPoint(x: size.width / 2, y: size.height / 2)
    ship.size  = CGSize(width: 40, height: 40)
    ship.name = "ship"
    addChild(ship)
    
    let thrust = SKEmitterNode.nodeWithFile("thrust.sks")!
    thrust.position = CGPoint(x: 0, y: -20)
    ship.addChild(thrust)
    
    shipExplodeTemplate = SKEmitterNode.nodeWithFile("shipExplode.sks")
    obstacleExplodeTemplate = SKEmitterNode.nodeWithFile("obstacleExplode.sks")
    
    // Add sounds
    shootSound = SKAction.playSoundFileNamed("shoot.m4a", waitForCompletion: false)
    obstacleExplodeSound = SKAction.playSoundFileNamed("obstacleExplode.m4a", waitForCompletion: false)
    shipExplodeSound = SKAction.playSoundFileNamed("shipExplode.m4a", waitForCompletion: false)
    
  }
  
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    shipTouch = touches.anyObject() as? UITouch
  }
  
  override func update(currentTime: NSTimeInterval) {
    
    if lastUpdateTime == nil {
      lastUpdateTime = currentTime
    }
    
    let timeDelta = currentTime - lastUpdateTime!
    
    if let touch = shipTouch {
      let pt = touch.locationInNode(self)
      moveShipTowardPoint(pt, byTimeDelta: timeDelta)
      
      if lastShotFireTime == nil || CGFloat(currentTime - lastShotFireTime!) > shipFireRate {
        shoot()
        lastShotFireTime = currentTime
      }
    }
    
    if arc4random_uniform(UInt32(1000)) <= 15 {
      dropThing()
    }
    
    checkCollisions()
    lastUpdateTime = currentTime
    
  }
  
  func randomCGFloatTo(limit: Int) -> CGFloat {
    return CGFloat(arc4random_uniform(UInt32(limit)))
  }
  
  func randomCGFloatTo(limit: CGFloat) -> CGFloat {
    return randomCGFloatTo(Int(limit))
  }
  
  func checkCollisions() {
    if let ship = childNodeWithName("ship") {
      enumerateChildNodesWithName("powerup") {
        powerup, stop in
        if ship.intersectsNode(powerup) {
          powerup.removeFromParent()
          self.shipFireRate = 0.1
          let powerdown = SKAction.runBlock({
            self.shipFireRate = 0.5
          })
          let wait = SKAction.waitForDuration(5.0)
          let waitAndPowerdown = SKAction.sequence([wait, powerdown])
          ship.removeActionForKey("waitAndPowerDown")
          ship.runAction(waitAndPowerdown, withKey: "waitAndPowerDown")
          
        }
      }
      enumerateChildNodesWithName("obstacle") {
        obstacle, stop in
        if ship.intersectsNode(obstacle) {
          self.shipTouch = nil
          ship.removeFromParent()
          obstacle.removeFromParent()
          self.runAction(self.shipExplodeSound)
          let explosion: SKEmitterNode = self.shipExplodeTemplate!.copy() as SKEmitterNode
          explosion.position = ship.position
          explosion.dieOutInDuration(0.3)
          self.addChild(explosion)
        }
        self.enumerateChildNodesWithName("photon") {
          photon, stop in
          if photon.intersectsNode(obstacle) {
            photon.removeFromParent()
            obstacle.removeFromParent()
            self.runAction(self.obstacleExplodeSound)
            
            let explosion: SKEmitterNode = self.obstacleExplodeTemplate!.copy() as SKEmitterNode
            explosion.position = obstacle.position
            explosion.dieOutInDuration(0.1)
            self.addChild(explosion)
            
            stop.memory = true
          }
        }
      }
    }
  }
  
  func dropThing() {
    let dice = arc4random_uniform(100)
    if dice < 5 {
      dropPowerup()
    } else if dice < 20 {
      dropEnemyShip()
    } else {
      dropAsteroid()
    }
  }
  
  func dropPowerup() {
    let sideSize = CGFloat(30)
    let startX = randomCGFloatTo(self.size.width - 60.0) + 30
    let startY = self.size.height + sideSize
    let endY = 0 - sideSize
    
    let powerup = SKSpriteNode(imageNamed: "powerup")
    powerup.name = "powerup"
    powerup.size = CGSize(width: sideSize, height: sideSize)
    powerup.position = CGPoint(x: startX, y: startY)
    addChild(powerup)
    
    let move = SKAction.moveTo(CGPoint(x: startX, y: endY), duration: NSTimeInterval(6))
    let spin = SKAction.rotateByAngle(-1.0, duration: NSTimeInterval(1))
    let remove = SKAction.removeFromParent()
    
    let spinForever = SKAction.repeatActionForever(spin)
    let travelAndRemove = SKAction.sequence([move, remove])
    let all = SKAction.group([spinForever, travelAndRemove])
    powerup.runAction(all)
  }
  
  func dropEnemyShip() {
    let sideSize = CGFloat(30.0)
    let startX = randomCGFloatTo(size.width - 40.0) + 20.0
    let startY = size.height + sideSize
    
    let enemy = SKSpriteNode(imageNamed: "enemy")
    enemy.size = CGSize(width: sideSize, height: sideSize)
    enemy.position = CGPoint(x: startX, y: startY)
    enemy.name = "obstacle"
    addChild(enemy)
    
    let shipPath = buildEnemyShipMovementPath()
    let followPath = SKAction.followPath(shipPath,
      asOffset: true,
      orientToPath: true,
      duration: NSTimeInterval(7))
    let remove = SKAction.removeFromParent()
    let all = SKAction.sequence([followPath, remove])
    enemy.runAction(all)
    
  }
  
  func buildEnemyShipMovementPath() -> CGPathRef {
    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPoint(x: 0.5, y: -0.5))
    bezierPath.addCurveToPoint(CGPoint(x: -2.5, y: -59.5),
      controlPoint1: CGPoint(x: 0.5, y: -0.5),
      controlPoint2: CGPoint(x: 4.55, y: -29.48))
    bezierPath.addCurveToPoint(CGPoint(x: -27.5, y: -154.5),
      controlPoint1: CGPoint(x: -9.55, y: -89.52),
      controlPoint2: CGPoint(x: -43.32, y: -115.43))
    bezierPath.addCurveToPoint(CGPoint(x: 30.5, y: -243.5),
      controlPoint1: CGPoint(x: -11.68, y: -193.57),
      controlPoint2: CGPoint(x: 17.28, y: -186.95))
    bezierPath.addCurveToPoint(CGPoint(x: -52.5, y: -379.5),
      controlPoint1: CGPoint(x: 42.72, y: -300.05),
      controlPoint2: CGPoint(x: -47.71, y: -335.76))
    bezierPath.addCurveToPoint(CGPoint(x: 54.5, y: -449.5),
      controlPoint1: CGPoint(x: -57.29, y: -423.24),
      controlPoint2: CGPoint(x: -8.14, y: -482.45))
    bezierPath.addCurveToPoint(CGPoint(x: -5.5, y: -348.5),
      controlPoint1: CGPoint(x: 117.14, y: -416.55),
      controlPoint2: CGPoint(x: 52.25, y: -308.62))
    bezierPath.addCurveToPoint(CGPoint(x: 0.5, y: -559.5),
      controlPoint1: CGPoint(x: 23.74, y: -514.16),
      controlPoint2: CGPoint(x: 6.93, y: -537.57))
    bezierPath.addCurveToPoint(CGPoint(x: -2.5, y: -644.5),
      controlPoint1: CGPoint(x: -5.2, y: -578.93),
      controlPoint2: CGPoint(x: -2.5, y: -644.5))
    return bezierPath.CGPath
  }
  
  func dropAsteroid() {
    let sideSize = CGFloat(15 + randomCGFloatTo(30))
    let maxX = CGFloat(self.size.width)
    
    let quarterX = maxX / 4
    
    let startX = randomCGFloatTo(maxX + (quarterX * 2)) - quarterX
    let startY = self.size.height + sideSize
    let endX = randomCGFloatTo(maxX)
    let endY = CGFloat(0 - sideSize)
    
    let asteroid = SKSpriteNode(imageNamed: "asteroid")
    asteroid.size = CGSize(width: sideSize, height: sideSize)
    
    asteroid.position = CGPoint(x: startX, y: startY)
    asteroid.name = "obstacle"
    addChild(asteroid)
    
    let move = SKAction.moveTo(CGPoint(x: endX, y: endY), duration: NSTimeInterval(3 + arc4random_uniform(UInt32(4))))
    let remove = SKAction.removeFromParent()
    let travelAndRemove = SKAction.sequence([move, remove])
    
    let spin = SKAction.rotateByAngle(3.0, duration: NSTimeInterval(arc4random_uniform(UInt32(2)) + 1))
    let spinForever = SKAction.repeatActionForever(spin)
    
    let all = SKAction.group([spinForever, travelAndRemove])
    asteroid.runAction(all)
  }
  
  func shoot() {
    if let ship = childNodeWithName("ship") {
      let photon = SKSpriteNode(imageNamed: "photon")
      photon.name = "photon"
      photon.position = ship.position
      addChild(photon)
      
      let fly = SKAction.moveByX(0,
        y: self.size.height + photon.size.height,
        duration: 0.5)
      let remove = SKAction.removeFromParent()
      let fireAndRemove = SKAction.sequence([fly, remove])
      photon.runAction(fireAndRemove)
      runAction(shootSound)
    }
  }
  
  func moveShipTowardPoint(point: CGPoint, byTimeDelta timeDelta: NSTimeInterval) {
    let shipSpeed = 130 // points per second
    if let ship = childNodeWithName("ship") {
      let distanceLeft = sqrt(pow(ship.position.x - point.x, 2) +
        pow(ship.position.y - point.y, 2))
      if distanceLeft > 4 {
        let distanceToTravel: CGFloat = CGFloat(timeDelta) * CGFloat(shipSpeed)
        let angle = atan2(point.y - ship.position.y, point.x - ship.position.x)
        let yOffset = distanceToTravel * sin(angle)
        let xOffset = distanceToTravel * cos(angle)
        
        ship.position = CGPoint(x: ship.position.x + xOffset,
          y: ship.position.y + yOffset)
      }
    }
  }
  
  //    override func didMoveToView(view: SKView) {
  //        /* Setup your scene here */
  //        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
  //        myLabel.text = "Hello, World!";
  //        myLabel.fontSize = 65;
  //        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
  //
  //        self.addChild(myLabel)
  //    }
  //
  //    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
  //        /* Called when a touch begins */
  //
  //        for touch: AnyObject in touches {
  //            let location = touch.locationInNode(self)
  //
  //            let sprite = SKSpriteNode(imageNamed:"Spaceship")
  //
  //            sprite.xScale = 0.5
  //            sprite.yScale = 0.5
  //            sprite.position = location
  //
  //            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
  //
  //            sprite.runAction(SKAction.repeatActionForever(action))
  //
  //            self.addChild(sprite)
  //        }
  //    }
  //
  //    override func update(currentTime: CFTimeInterval) {
  //        /* Called before each frame is rendered */
  //    }
}
