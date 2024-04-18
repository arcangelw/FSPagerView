//
//  FSPagerViewLayoutAttributes.swift
//  FSPagerViewExample
//
//  Created by Wenchao Ding on 26/02/2017.
//  Copyright © 2017 Wenchao Ding. All rights reserved.
//

import UIKit

open class FSPagerViewLayoutAttributes: UICollectionViewLayoutAttributes {
    // The position property represents the position of the pager view item.
    open var position: CGFloat = 0

    // Override isEqual to compare the current object with another object.
    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? FSPagerViewLayoutAttributes else {
            return false
        }
        return super.isEqual(object) && position == object.position
    }

    // Override copy method to duplicate the layout attributes.
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! FSPagerViewLayoutAttributes
        copy.position = position
        return copy
    }
}
