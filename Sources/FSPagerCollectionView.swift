//
//  FSPagerCollectionView.swift
//  FSPagerView
//
//  Created by Wenchao Ding on 24/12/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//
//  1. Reject -[UIScrollView(UIScrollViewInternal) _adjustContentOffsetIfNecessary]
//  2. Group initialized features

import UIKit

class FSPagerCollectionView: UICollectionView {
    #if !os(tvOS)
        /// Prevents the scrollsToTop behavior on iOS, as we handle scroll top behavior explicitly in the collection view.
        override var scrollsToTop: Bool {
            set {
                super.scrollsToTop = false // Disables the default behavior
            }
            get {
                return false // Always returns false to prevent scrolls to top
            }
        }
    #endif

    /// Custom setter and getter for `contentInset`.
    /// This setter overrides the default behavior by setting the contentInset to zero.
    /// It also adjusts the content offset if the new value's top inset is greater than 0.
    override var contentInset: UIEdgeInsets {
        set {
            super.contentInset = .zero // Resets the content inset to zero
            if newValue.top > 0 {
                // Adjust the content offset by adding the new top inset to the current offset
                let contentOffset = CGPoint(x: self.contentOffset.x, y: self.contentOffset.y + newValue.top)
                self.contentOffset = contentOffset
            }
        }
        get {
            return super.contentInset // Returns the default contentInset value
        }
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit() // Initialize the custom properties
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit() // Initialize the custom properties
    }

    /// Initializes custom properties of the collection view.
    fileprivate func commonInit() {
        contentInset = .zero // Resets the content inset
        decelerationRate = UIScrollView.DecelerationRate.fast // Sets fast deceleration for smooth scrolling
        showsVerticalScrollIndicator = false // Hides the vertical scroll indicator
        showsHorizontalScrollIndicator = false // Hides the horizontal scroll indicator
        isPrefetchingEnabled = false // Disables prefetching of cells for performance
        contentInsetAdjustmentBehavior = .never // Prevents automatic content inset adjustments
        #if !os(tvOS)
            scrollsToTop = false // Prevents the default scroll to top behavior on iOS
            isPagingEnabled = false // Disables paging
        #endif
    }
}
