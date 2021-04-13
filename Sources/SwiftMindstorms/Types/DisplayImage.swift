//
//  DisplayImage.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct DisplayImage: IRequest {
    public static let name = "scratch.display_image"
    public var image: Bitmap
    public init(image: Bitmap) {
        self.image = image
    }
}
