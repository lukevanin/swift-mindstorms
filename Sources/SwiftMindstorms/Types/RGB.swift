//
//  RGB.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct RGB: Codable {
    public let r: Int
    public let g: Int
    public let b: Int
    public init(r: Int, g: Int, b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }
}

public struct RGBA: Codable {
    public let r: Int
    public let g: Int
    public let b: Int
    public let a: Int
    public init(r: Int, g: Int, b: Int, a: Int) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}
