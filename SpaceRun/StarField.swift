//
//  StarField.swift
//  SpaceRun
//
//  Created by Martin Volerich on 9/12/14.
//  Copyright (c) 2014 Bill Bear. All rights reserved.
//

import SpriteKit

class StarField :SKNode {
  override init() {
    super.init()
    weak var weakSelf = self
    let update = SKAction.runBlock({
      if arc4random_uniform(10) < 3 {
        weakSelf!.launchStar()
      }
    })
    let delay = SKAction.waitForDuration(0.01)
    let updateLoop = SKAction.sequence([delay, update])
    runAction(SKAction.repeatActionForever(updateLoop))
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    weak var weakSelf = self
    let update = SKAction.runBlock({
      if arc4random_uniform(10) < 3 {
        weakSelf!.launchStar()
      }
    })
    let delay = SKAction.waitForDuration(0.01)
    let updateLoop = SKAction.sequence([delay, update])
    runAction(SKAction.repeatActionForever(updateLoop))
  }
  
  func launchStar() {
    let randX = CGFloat(arc4random_uniform(UInt32(self.scene!.size.width)))
    let maxY = self.scene!.size.height
    let randomStart = CGPoint(x: randX, y: maxY)
    
    let star = SKSpriteNode(imageNamed: "shootingstar")
    star.position = randomStart
    star.size = CGSize(width: 2, height: 10)
    star.alpha = 0.1 + (CGFloat(arc4random_uniform(10)) / 10.0)
    addChild(star)
    
    let destY = 0 - scene!.size.height - star.size.height
    let duration = 0.1 + CGFloat(arc4random_uniform(10)) / 10.0
    
    let move = SKAction.moveByX(0, y: destY, duration: NSTimeInterval(duration))
    let remove = SKAction.removeFromParent()
    star.runAction(SKAction.sequence([move, remove]))
  }
}
