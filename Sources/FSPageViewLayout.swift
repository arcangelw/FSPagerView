//
//  FSPageViewLayout.swift
//  FSPagerView
//
//  Created by Wenchao Ding on 20/12/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

import UIKit

/// Layout responsible for arranging FSPagerView items.
/// Handles paging behavior, scroll direction, spacing, and item sizing.
class FSPagerViewLayout: UICollectionViewLayout {
    var contentSize: CGSize = .zero
    var leadingSpacing: CGFloat = 0
    var itemSpacing: CGFloat = 0
    var needsReprepare = true
    var scrollDirection: FSPagerView.ScrollDirection = .horizontal

    override open class var layoutAttributesClass: AnyClass {
        return FSPagerViewLayoutAttributes.self
    }

    fileprivate var pagerView: FSPagerView? {
        return collectionView?.superview?.superview as? FSPagerView
    }

    fileprivate var collectionViewSize: CGSize = .zero
    fileprivate var numberOfSections = 1
    fileprivate var numberOfItems = 0
    fileprivate var actualInteritemSpacing: CGFloat = 0
    fileprivate var actualItemSize: CGSize = .zero

    override init() {
        super.init()
        setupNotificationObservers()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNotificationObservers()
    }

    deinit {
        #if !os(tvOS)
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        #endif
    }

    override open func prepare() {
        guard let collectionView = collectionView, let pagerView = pagerView else {
            return
        }
        guard needsReprepare || collectionViewSize != collectionView.frame.size else {
            return
        }
        needsReprepare = false

        collectionViewSize = collectionView.frame.size

        // Calculate basic parameters/variables
        numberOfSections = pagerView.numberOfSections(in: collectionView)
        numberOfItems = pagerView.collectionView(collectionView, numberOfItemsInSection: 0)
        actualItemSize = {
            let sizeMode = pagerView.itemSizeMode
            let collectionViewSize = collectionView.frame.size
            guard !sizeMode.isAutomatic else { return collectionViewSize }
            switch sizeMode {
            case let .size(size): return size
            case let .aspectRatio(aspectRatio):
                let width = collectionViewSize.height * aspectRatio
                if width <= collectionViewSize.width {
                    return CGSize(width: width, height: collectionViewSize.height)
                }
                let height = collectionViewSize.width / aspectRatio
                return CGSize(width: collectionViewSize.width, height: height)
            case let .insets(insets):
                return CGRect(origin: .zero, size: collectionViewSize).inset(by: insets).size
            }
        }()

        actualInteritemSpacing = {
            if let transformer = pagerView.transformer {
                return transformer.proposedInteritemSpacing()
            }
            return pagerView.interitemSpacing
        }()
        scrollDirection = pagerView.scrollDirection
        leadingSpacing = {
            var spacing = pagerView.leadingSpacing
            if spacing.isZero {
                spacing = self.scrollDirection == .horizontal ? (collectionView.frame.width - self.actualItemSize.width) * 0.5 : (collectionView.frame.height - self.actualItemSize.height) * 0.5
            }
            return spacing
        }()
        itemSpacing = (scrollDirection == .horizontal ? actualItemSize.width : actualItemSize.height) + actualInteritemSpacing

        // Calculate and cache contentSize, rather than calculating each time
        contentSize = {
            let numberOfItems = self.numberOfItems * self.numberOfSections
            switch self.scrollDirection {
            case .horizontal:
                var contentSizeWidth: CGFloat = self.leadingSpacing * 2 // Leading & trailing spacing
                contentSizeWidth += CGFloat(numberOfItems - 1) * self.actualInteritemSpacing // Interitem spacing
                contentSizeWidth += CGFloat(numberOfItems) * self.actualItemSize.width // Item sizes
                let contentSize = CGSize(width: contentSizeWidth, height: collectionView.frame.height)
                return contentSize
            case .vertical:
                var contentSizeHeight: CGFloat = self.leadingSpacing * 2 // Leading & trailing spacing
                contentSizeHeight += CGFloat(numberOfItems - 1) * self.actualInteritemSpacing // Interitem spacing
                contentSizeHeight += CGFloat(numberOfItems) * self.actualItemSize.height // Item sizes
                let contentSize = CGSize(width: collectionView.frame.width, height: contentSizeHeight)
                return contentSize
            }
        }()
        adjustCollectionViewBounds()
    }

    override open var collectionViewContentSize: CGSize {
        return contentSize
    }

    override open func shouldInvalidateLayout(forBoundsChange _: CGRect) -> Bool {
        return true
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let pagerView = pagerView else {
            return []
        }
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        guard itemSpacing > 0, !rect.isEmpty else {
            return layoutAttributes
        }
        let rect = rect.intersection(CGRect(origin: .zero, size: contentSize))
        guard !rect.isEmpty else {
            return layoutAttributes
        }
        // Calculate start position and index of certain rects
        let numberOfItemsBefore = scrollDirection == .horizontal ? max(Int((rect.minX - leadingSpacing) / itemSpacing), 0) : max(Int((rect.minY - leadingSpacing) / itemSpacing), 0)
        let startPosition = leadingSpacing + CGFloat(numberOfItemsBefore) * itemSpacing
        let startIndex = numberOfItemsBefore
        // Create layout attributes
        var itemIndex = startIndex

        var origin = startPosition
        let maxPosition = scrollDirection == .horizontal ? min(rect.maxX, contentSize.width - actualItemSize.width - leadingSpacing) : min(rect.maxY, contentSize.height - actualItemSize.height - leadingSpacing)
        // https://stackoverflow.com/a/10335601/2398107
        while origin - maxPosition <= max(CGFloat(100.0) * .ulpOfOne * abs(origin + maxPosition), .leastNonzeroMagnitude) {
            let indexPath = IndexPath(item: itemIndex % numberOfItems, section: itemIndex / numberOfItems)
            let attributes = layoutAttributesForItem(at: indexPath) as! FSPagerViewLayoutAttributes
            applyTransform(to: attributes, with: pagerView.transformer)
            layoutAttributes.append(attributes)
            itemIndex += 1
            origin += itemSpacing
        }
        return layoutAttributes
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = FSPagerViewLayoutAttributes(forCellWith: indexPath)
        attributes.indexPath = indexPath
        let frame = self.frame(for: indexPath)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        attributes.center = center
        attributes.size = actualItemSize
        return attributes
    }

    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView, let pagerView = pagerView else {
            return proposedContentOffset
        }
        var proposedContentOffset = proposedContentOffset

        func calculateTargetOffset(by proposedOffset: CGFloat, boundedOffset: CGFloat) -> CGFloat {
            var targetOffset: CGFloat
            if pagerView.decelerationDistance == FSPagerView.automaticDistance {
                if abs(velocity.x) >= 0.3 {
                    let vector: CGFloat = velocity.x >= 0 ? 1.0 : -1.0
                    targetOffset = round(proposedOffset / itemSpacing + 0.35 * vector) * itemSpacing // Ceil by 0.15, rather than 0.5
                } else {
                    targetOffset = round(proposedOffset / itemSpacing) * itemSpacing
                }
            } else {
                let extraDistance = max(pagerView.decelerationDistance - 1, 0)
                switch velocity.x {
                case 0.3 ... CGFloat.greatestFiniteMagnitude:
                    targetOffset = ceil(collectionView.contentOffset.x / itemSpacing + CGFloat(extraDistance)) * itemSpacing
                case -CGFloat.greatestFiniteMagnitude ... -0.3:
                    targetOffset = floor(collectionView.contentOffset.x / itemSpacing - CGFloat(extraDistance)) * itemSpacing
                default:
                    targetOffset = round(proposedOffset / itemSpacing) * itemSpacing
                }
            }
            targetOffset = max(0, targetOffset)
            targetOffset = min(boundedOffset, targetOffset)
            return targetOffset
        }
        let proposedContentOffsetX: CGFloat = {
            if self.scrollDirection == .vertical {
                return proposedContentOffset.x
            }
            let boundedOffset = collectionView.contentSize.width - self.itemSpacing
            return calculateTargetOffset(by: proposedContentOffset.x, boundedOffset: boundedOffset)
        }()
        let proposedContentOffsetY: CGFloat = {
            if self.scrollDirection == .horizontal {
                return proposedContentOffset.y
            }
            let boundedOffset = collectionView.contentSize.height - self.itemSpacing
            return calculateTargetOffset(by: proposedContentOffset.y, boundedOffset: boundedOffset)
        }()
        proposedContentOffset = CGPoint(x: proposedContentOffsetX, y: proposedContentOffsetY)
        return proposedContentOffset
    }

    // MARK: - Internal functions

    /// Marks the layout as needing re-preparation and invalidates the layout.
    func invalidateAndReprepare() {
        needsReprepare = true
        invalidateLayout()
    }

    /// Calculates the target content offset to center the item at the given indexPath.
    /// - Parameter indexPath: The index path of the item.
    /// - Returns: The CGPoint representing the content offset.
    func contentOffset(for indexPath: IndexPath) -> CGPoint {
        let origin = frame(for: indexPath).origin
        guard let collectionView = collectionView else {
            return origin
        }
        let contentOffsetX: CGFloat = {
            if self.scrollDirection == .vertical {
                return 0
            }
            let contentOffsetX = origin.x - (collectionView.frame.width * 0.5 - self.actualItemSize.width * 0.5)
            return contentOffsetX
        }()
        let contentOffsetY: CGFloat = {
            if self.scrollDirection == .horizontal {
                return 0
            }
            let contentOffsetY = origin.y - (collectionView.frame.height * 0.5 - self.actualItemSize.height * 0.5)
            return contentOffsetY
        }()
        let contentOffset = CGPoint(x: contentOffsetX, y: contentOffsetY)
        return contentOffset
    }

    /// Calculates the frame for the item at the given indexPath.
    /// - Parameter indexPath: The index path of the item.
    /// - Returns: The CGRect representing the item's frame.
    func frame(for indexPath: IndexPath) -> CGRect {
        let numberOfItems = self.numberOfItems * indexPath.section + indexPath.item
        let originX: CGFloat = {
            if self.scrollDirection == .vertical {
                return (self.collectionView!.frame.width - self.actualItemSize.width) * 0.5
            }
            return self.leadingSpacing + CGFloat(numberOfItems) * self.itemSpacing
        }()
        let originY: CGFloat = {
            if self.scrollDirection == .horizontal {
                return (self.collectionView!.frame.height - self.actualItemSize.height) * 0.5
            }
            return self.leadingSpacing + CGFloat(numberOfItems) * self.itemSpacing
        }()
        let origin = CGPoint(x: originX, y: originY)
        let frame = CGRect(origin: origin, size: actualItemSize)
        return frame
    }

    // MARK: - Notification

    /// Handles device orientation changes by adjusting collectionView bounds if necessary.
    @objc
    fileprivate func handleDeviceOrientationChange(notification _: Notification) {
        if pagerView?.itemSize == .zero {
            adjustCollectionViewBounds()
        }
    }

    // MARK: - Private functions

    /// Sets up observers for device orientation changes to adjust layout dynamically.
    fileprivate func setupNotificationObservers() {
        #if !os(tvOS)
            NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        #endif
    }

    /// Adjusts the collection view's bounds to ensure the current item is centered.
    fileprivate func adjustCollectionViewBounds() {
        guard let collectionView = collectionView, let pagerView = pagerView else {
            return
        }
        let currentIndex = pagerView.currentIndex
        let newIndexPath = IndexPath(item: currentIndex, section: pagerView.isInfinite ? numberOfSections / 2 : 0)
        let contentOffset = self.contentOffset(for: newIndexPath)
        let newBounds = CGRect(origin: contentOffset, size: collectionView.frame.size)
        collectionView.bounds = newBounds
    }

    /// Applies the custom transform to the layout attributes for animation effects.
    /// - Parameters:
    ///   - attributes: The layout attributes to be transformed.
    ///   - transformer: The transformer providing animation logic.
    fileprivate func applyTransform(to attributes: FSPagerViewLayoutAttributes, with transformer: FSPagerViewTransformer?) {
        guard let collectionView = collectionView else {
            return
        }
        guard let transformer = transformer else {
            return
        }
        switch scrollDirection {
        case .horizontal:
            let ruler = collectionView.bounds.midX
            attributes.position = (attributes.center.x - ruler) / itemSpacing
        case .vertical:
            let ruler = collectionView.bounds.midY
            attributes.position = (attributes.center.y - ruler) / itemSpacing
        }
        attributes.zIndex = Int(numberOfItems) - Int(attributes.position)
        transformer.applyTransform(to: attributes)
    }
}
