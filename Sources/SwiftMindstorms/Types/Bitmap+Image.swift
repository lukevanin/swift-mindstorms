//
//  Bitmap+UIImage.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/12.
//

#if !os(macOS)
import UIKit
import SwiftUI

public let defaultSize = CGSize(width: 256, height: 256)

extension Bitmap {
    public func image(size: CGSize = defaultSize) -> Image {
        return Image(uiImage: uiImage())
    }
    
    public func uiImage(size: CGSize = defaultSize) -> UIImage {
        let spacing = CGFloat(4)
        let totalSpacing = CGSize(
            width: spacing * CGFloat(dimensions.x - 1),
            height: spacing * CGFloat(dimensions.y - 1)
        )
        let itemSize = CGSize(
            width: (size.width - totalSpacing.width) / CGFloat(dimensions.x),
            height: (size.height - totalSpacing.height) / CGFloat(dimensions.y)
        )
        let stepSize = CGSize(
            width: itemSize.width + spacing,
            height: itemSize.height + spacing
        )
        let bounds = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(
            bounds: bounds,
            format: format
        )
        return renderer.image { context in
            for y in 0 ..< dimensions.y {
                for x in 0 ..< dimensions.x {
                    // Get the intensity of the pixel at the coordinate.
                    let c = Coordinate(x: x, y: y)
                    let i = self[c]
                    // Skip dark pixels (intensity zero).
                    guard i > 0 else {
                        continue
                    }
                    // Convert pixel intensity range [0...9] to UIColor
                    // component value range [0...1]
                    let k = round(CGFloat(i) / 9)
                    let color = UIColor(white: k, alpha: 1)
                    // Calculate position and size of rectangle representing the
                    // iamge pixel in the output image space.
                    let origin = CGPoint(
                        x: CGFloat(x) * stepSize.width,
                        y: CGFloat(y) * stepSize.height
                    )
                    let rect = CGRect(
                        origin: origin,
                        size: itemSize
                    )
                    // Render the pixel rectangle in the output image.
                    color.setFill()
                    context.fill(rect)
                }
            }
//            context.fill(<#T##rect: CGRect##CGRect#>)
        }
    }
}
#endif
