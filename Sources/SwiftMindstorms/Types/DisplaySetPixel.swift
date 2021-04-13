//
//  DisplaySetPixel.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct DisplaySetPixel: IRequest {
    public static let name = "scratch.display_set_pixel"
    public var x: Int
    public var y: Int
    public var brightness: Int
    public init(x: Int, y: Int, brightness: Int) {
        self.x = x
        self.y = y
        self.brightness = brightness
    }
}
