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
  var lastUpdateTime: NSTimeInterval? = nil
  var lastShotFireTime: NSTimeInterval? = nil
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    backgroundColor = SKColor.blackColor()
    let name = "Spaceship.png"
    let ship = SKSpriteNode(imageNamed: name)
    let size = self.size
    ship.position = CGPoint(x: size.width / 2, y: size.height / 2)
    ship.size  = CGSize(width: 40, height: 40)
    ship.name = "ship"
    addChild(ship)
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
      
      if lastShotFireTime == nil || currentTime - lastShotFireTime! > 0.5 {
        shoot()
        lastShotFireTime = currentTime
      }
      
      lastUpdateTime = currentTime
    }
    
  }
  
  func shoot() {
    let ship = childNodeWithName("ship")!
    let photon = SKSpriteNode(imageNamed: "photon")
    photon.name = "photon"
    photon.position = ship.position
    addChild(photon)
    
    let fly = SKAction.moveByX(0,
      y: self.size.height + photon.size.height,
      duration: 0.5)
    photon.runAction(fly)
    
    
  }
  
  func moveShipTowardPoint(point: CGPoint, byTimeDelta timeDelta: NSTimeInterval) {
    let shipSpeed = 130 // points per second
    let ship = childNodeWithName("ship")!
    
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
