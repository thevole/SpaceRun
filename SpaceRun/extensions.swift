//
//  extensions.swift
//  SpaceRun
//
//  Created by Martin Volerich on 9/12/14.
//  Copyright (c) 2014 Bill Bear. All rights reserved.
//

import SpriteKit

extension SKEmitterNode {
  class func nodeWithFile(filename: String) -> SKEmitterNode? {
    let basename = filename.stringByDeletingPathExtension
    
    var extensionText = filename.pathExtension
    if extensionText == "" {
      extensionText = "sks"
    }
    
    let path = NSBundle.mainBundle().pathForResource(basename, ofType: extensionText)
    
    var sceneData = NSData.dataWithContentsOfFile(path!, options: .DataReadingMappedIfSafe, error: nil)
    var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
    
    archiver.setClass(SKEmitterNode.self, forClassName: "SKEditorScene")
    let node = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as SKEmitterNode?
    archiver.finishDecoding()
    return node
  }
  
  func dieOutInDuration(duration: NSTimeInterval) {
    let firstWait = SKAction.waitForDuration(duration)
    weak var weakSelf: SKEmitterNode! = self
    let stop = SKAction.runBlock {
      weakSelf.particleBirthRate = 0.0
    }
    let secondWait = SKAction.waitForDuration(NSTimeInterval(particleLifetime))
    let remove = SKAction.removeFromParent()
    let dieOut = SKAction.sequence([firstWait, stop, secondWait, remove])
    self.runAction(dieOut)
  }
}
