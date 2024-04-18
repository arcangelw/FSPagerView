//
//  FSPagerViewCell.swift
//  FSPagerView
//
//  Created by Wenchao Ding on 17/12/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

import UIKit

/// A reusable pager view cell that supports an image view and a text label.
open class FSPagerViewCell: UICollectionViewCell {
    /// The label used for the main textual content of the pager view cell.
    @objc
    open var textLabel: UILabel? {
        if let label = _textLabel {
            return label
        }
        let backgroundView = UIView(frame: .zero)
        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .body)

        contentView.addSubview(backgroundView)
        backgroundView.addSubview(label)

        label.addObserver(self, forKeyPath: "font", options: [.old, .new], context: kvoContext)

        _textLabel = label
        return label
    }

    /// The image view used to display the image content of the pager view cell.
    @objc
    open var imageView: UIImageView? {
        if let imageView = _imageView {
            return imageView
        }
        let imgView = UIImageView(frame: .zero)
        contentView.addSubview(imgView)
        _imageView = imgView
        return imgView
    }

    private weak var _textLabel: UILabel?
    private weak var _imageView: UIImageView?

    private let kvoContext = UnsafeMutableRawPointer(bitPattern: 0)
    private let selectionColor = UIColor(white: 0.2, alpha: 0.2)

    private weak var _selectedForegroundView: UIView?

    /// A view that overlays the image view to indicate selection or highlight state.
    private var selectedForegroundView: UIView? {
        if let view = _selectedForegroundView {
            return view
        }
        guard let imageView = _imageView else {
            return nil
        }
        let overlay = UIView(frame: imageView.bounds)
        imageView.addSubview(overlay)
        _selectedForegroundView = overlay
        return overlay
    }

    // MARK: - State Handling

    override open var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            selectedForegroundView?.layer.backgroundColor = newValue ? selectionColor.cgColor : (super.isSelected ? selectionColor.cgColor : UIColor.clear.cgColor)
        }
        get {
            return super.isHighlighted
        }
    }

    override open var isSelected: Bool {
        set {
            super.isSelected = newValue
            selectedForegroundView?.layer.backgroundColor = newValue ? selectionColor.cgColor : UIColor.clear.cgColor
        }
        get {
            return super.isSelected
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    /// Common initialization for the pager view cell.
    private func commonInit() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowRadius = 5
        contentView.layer.shadowOpacity = 0.75
        contentView.layer.shadowOffset = .zero
    }

    deinit {
        _textLabel?.removeObserver(self, forKeyPath: "font", context: kvoContext)
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()

        _imageView?.frame = contentView.bounds

        if let textLabel = _textLabel, let backgroundView = textLabel.superview {
            backgroundView.frame = {
                var rect = contentView.bounds
                let height = textLabel.font.pointSize * 1.5
                rect.size.height = height
                rect.origin.y = contentView.frame.height - height
                return rect
            }()
            textLabel.frame = {
                var rect = backgroundView.bounds
                rect = rect.insetBy(dx: 8, dy: 0)
                rect.size.height -= 1
                rect.origin.y += 1
                return rect
            }()
        }

        _selectedForegroundView?.frame = contentView.bounds
    }

    // MARK: - Key-Value Observing

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == kvoContext {
            if keyPath == "font" {
                setNeedsLayout()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
