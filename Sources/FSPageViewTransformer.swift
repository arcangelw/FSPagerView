//
//  FSPageViewTransformer.swift
//  FSPagerView
//
//  Created by Wenchao Ding on 05/01/2017.
//  Copyright © 2017 Wenchao Ding. All rights reserved.
//

import UIKit

@objc
public enum FSPagerViewTransformerType: Int {
    case crossFading
    case zoomOut
    case depth
    case overlap
    case linear
    case coverFlow
    case ferrisWheel
    case invertedFerrisWheel
    case cubic
}

/// A transformer that applies visual effects to pager view items based on their position.
open class FSPagerViewTransformer: NSObject {
    /// The pager view associated with this transformer.
    open internal(set) weak var pagerView: FSPagerView?
    /// The type of transformation to apply.
    open internal(set) var type: FSPagerViewTransformerType

    /// The minimum scale applied to pager view items during transformation.
    @objc open var minimumScale: CGFloat = 0.65
    /// The minimum alpha applied to pager view items during transformation.
    @objc open var minimumAlpha: CGFloat = 0.6

    /// Initializes a transformer with a specific type.
    ///
    /// - Parameter type: The type of transformation to apply.
    @objc
    public init(type: FSPagerViewTransformerType) {
        self.type = type
        switch type {
        case .zoomOut:
            minimumScale = 0.85
        case .depth:
            minimumScale = 0.5
        default:
            break
        }
    }

    /// Applies the transformation to the given layout attributes based on the current transformer type.
    ///
    /// - Parameter attributes: The layout attributes of a pager view item to transform.
    open func applyTransform(to attributes: FSPagerViewLayoutAttributes) {
        guard let pagerView = pagerView else { return }

        let position = attributes.position
        let scrollDirection = pagerView.scrollDirection
        let itemSpacing = (scrollDirection == .horizontal ? attributes.bounds.width : attributes.bounds.height) + proposedInteritemSpacing()

        switch type {
        case .crossFading:
            // Slide transition with cross-fading effect.
            var transform = CGAffineTransform.identity
            switch scrollDirection {
            case .horizontal:
                transform.tx = -itemSpacing * position
            case .vertical:
                transform.ty = -itemSpacing * position
            }
            attributes.alpha = abs(position) < 1 ? 1 - abs(position) : 0
            attributes.transform = transform
            attributes.zIndex = abs(position) < 1 ? 1 : Int.min

        case .zoomOut:
            // Zoom out effect combined with fading and sliding.
            var transform = CGAffineTransform.identity
            switch position {
            case -CGFloat.greatestFiniteMagnitude ..< -1:
                attributes.alpha = 0
            case -1 ... 1:
                let scaleFactor = max(minimumScale, 1 - abs(position))
                transform.a = scaleFactor
                transform.d = scaleFactor

                switch scrollDirection {
                case .horizontal:
                    let vertMargin = attributes.bounds.height * (1 - scaleFactor) / 2
                    let horzMargin = itemSpacing * (1 - scaleFactor) / 2
                    transform.tx = position < 0 ? (horzMargin - vertMargin * 2) : (-horzMargin + vertMargin * 2)
                case .vertical:
                    let horzMargin = attributes.bounds.width * (1 - scaleFactor) / 2
                    let vertMargin = itemSpacing * (1 - scaleFactor) / 2
                    transform.ty = position < 0 ? (vertMargin - horzMargin * 2) : (-vertMargin + horzMargin * 2)
                }

                attributes.alpha = minimumAlpha + (scaleFactor - minimumScale) / (1 - minimumScale) * (1 - minimumAlpha)
            case 1 ... CGFloat.greatestFiniteMagnitude:
                attributes.alpha = 0
            default:
                break
            }
            attributes.transform = transform

        case .depth:
            // Depth effect with fading and scaling based on position.
            var transform = CGAffineTransform.identity
            switch position {
            case -CGFloat.greatestFiniteMagnitude ..< -1:
                attributes.alpha = 0
                attributes.zIndex = 0
            case -1 ... 0:
                attributes.alpha = 1
                transform.tx = 0
                transform.a = 1
                transform.d = 1
                attributes.zIndex = 1
            case 0 ..< 1:
                attributes.alpha = 1 - position
                switch scrollDirection {
                case .horizontal:
                    transform.tx = -itemSpacing * position
                case .vertical:
                    transform.ty = -itemSpacing * position
                }
                let scaleFactor = minimumScale + (1 - minimumScale) * (1 - abs(position))
                transform.a = scaleFactor
                transform.d = scaleFactor
                attributes.zIndex = 0
            case 1 ... CGFloat.greatestFiniteMagnitude:
                attributes.alpha = 0
                attributes.zIndex = 0
            default:
                break
            }
            attributes.transform = transform

        case .overlap, .linear:
            // Overlapping or linear scaling effect (horizontal only).
            guard scrollDirection == .horizontal else { return }
            let scale = max(1 - (1 - minimumScale) * abs(position), minimumScale)
            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
            attributes.alpha = minimumAlpha + (1 - abs(position)) * (1 - minimumAlpha)
            attributes.zIndex = Int((1 - abs(position)) * 10)

        case .coverFlow:
            // Cover flow 3D rotation effect (horizontal only).
            guard scrollDirection == .horizontal else { return }
            let clampedPosition = min(max(-position, -1), 1)
            let rotation = sin(clampedPosition * .pi * 0.5) * .pi * 0.25 * 1.5
            let translationZ = -itemSpacing * 0.5 * abs(clampedPosition)
            var transform3D = CATransform3DIdentity
            transform3D.m34 = -0.002
            transform3D = CATransform3DRotate(transform3D, rotation, 0, 1, 0)
            transform3D = CATransform3DTranslate(transform3D, 0, 0, translationZ)
            attributes.zIndex = 100 - Int(abs(clampedPosition))
            attributes.transform3D = transform3D

        case .ferrisWheel, .invertedFerrisWheel:
            // Ferris wheel rotation effect (horizontal only).
            guard scrollDirection == .horizontal else { return }
            var transform = CGAffineTransform.identity
            if (-5 ... 5).contains(position) {
                let count: CGFloat = 14
                let circle = CGFloat.pi * 2
                let radius = (attributes.bounds.width + proposedInteritemSpacing()) * count / circle
                let ty = radius * (type == .ferrisWheel ? 1 : -1)
                let theta = circle / count
                let rotation = position * theta * (type == .ferrisWheel ? 1 : -1)
                transform = transform.translatedBy(x: -position * (attributes.bounds.width + proposedInteritemSpacing()), y: ty)
                transform = transform.rotated(by: rotation)
                transform = transform.translatedBy(x: 0, y: -ty)
                attributes.zIndex = Int(4.0 - abs(position) * 10)
            }
            attributes.alpha = abs(position) < 0.5 ? 1 : minimumAlpha
            attributes.transform = transform

        case .cubic:
            // Cubic rotation effect with 3D transform.
            switch position {
            case -CGFloat.greatestFiniteMagnitude ... -1:
                attributes.alpha = 0
            case -1 ..< 1:
                attributes.alpha = 1
                attributes.zIndex = Int((1 - position) * 10)
                let direction: CGFloat = position < 0 ? 1 : -1
                let theta = position * .pi * 0.5 * (scrollDirection == .horizontal ? 1 : -1)
                let radius = scrollDirection == .horizontal ? attributes.bounds.width : attributes.bounds.height
                var transform3D = CATransform3DIdentity
                transform3D.m34 = -0.002
                switch scrollDirection {
                case .horizontal:
                    attributes.center.x += direction * radius * 0.5
                    transform3D = CATransform3DRotate(transform3D, theta, 0, 1, 0)
                    transform3D = CATransform3DTranslate(transform3D, -direction * radius * 0.5, 0, 0)
                case .vertical:
                    attributes.center.y += direction * radius * 0.5
                    transform3D = CATransform3DRotate(transform3D, theta, 1, 0, 0)
                    transform3D = CATransform3DTranslate(transform3D, 0, -direction * radius * 0.5, 0)
                }
                attributes.transform3D = transform3D
            case 1 ... CGFloat.greatestFiniteMagnitude:
                attributes.alpha = 0
            default:
                attributes.alpha = 0
                attributes.zIndex = 0
            }
        }
    }

    /// Provides a proposed inter-item spacing override based on the transformer type.
    ///
    /// - Returns: The inter-item spacing to be used between pager view items.
    open func proposedInteritemSpacing() -> CGFloat {
        guard let pagerView = pagerView else { return 0 }
        let scrollDirection = pagerView.scrollDirection

        switch type {
        case .overlap where scrollDirection == .horizontal:
            return pagerView.itemSize.width * -minimumScale * 0.6
        case .linear where scrollDirection == .horizontal:
            return pagerView.itemSize.width * -minimumScale * 0.2
        case .coverFlow where scrollDirection == .horizontal:
            return -pagerView.itemSize.width * sin(.pi * 0.25 * 0.25 * 3.0)
        case .ferrisWheel, .invertedFerrisWheel where scrollDirection == .horizontal:
            return -pagerView.itemSize.width * 0.15
        case .cubic:
            return 0
        default:
            return pagerView.interitemSpacing
        }
    }
}
