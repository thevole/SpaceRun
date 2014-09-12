//
//  extensions.swift
//  SpaceRun
//
//  Created by Martin Volerich on 9/12/14.
//  Copyright (c) 2014 Bill Bear. All rights reserved.
//

import SpriteKit

extension SKEmitterNode {
  func nodeWithFile(filename: String) -> SKEmitterNode {
    let basename = filename.stringByDeletingPathExtension
    var extensionText = filename.pathExtension
    if extensionText == "" {
      extensionText = "sks"
    }
    let path = NSBundle.mainBundle().pathForResource(basename, ofType: extensionText)
    let node = NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as SKEmitterNode
    return node
  }
}
