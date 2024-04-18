//
//  TransformerExampleViewController.swift
//  FSPagerViewExample
//
//  Created by Wenchao Ding on 09/01/2017.
//  Copyright © 2017 Wenchao Ding. All rights reserved.
//

import UIKit

class TransformerExampleViewController: UIViewController, FSPagerViewDataSource, FSPagerViewDelegate, UITableViewDataSource, UITableViewDelegate {
    fileprivate let imageNames = ["1.jpg", "2.jpg", "3.jpg", "4.jpg", "5.jpg", "6.jpg", "7.jpg"]
    fileprivate let transformerNames = ["cross fading", "zoom out", "depth", "linear", "overlap", "ferris wheel", "inverted ferris wheel", "coverflow", "cubic"]
    fileprivate let transformerTypes: [FSPagerViewTransformerType] = [.crossFading,
                                                                      .zoomOut,
                                                                      .depth,
                                                                      .linear,
                                                                      .overlap,
                                                                      .ferrisWheel,
                                                                      .invertedFerrisWheel,
                                                                      .coverFlow,
                                                                      .cubic]
    fileprivate var typeIndex = 0 {
        didSet {
            let type = transformerTypes[typeIndex]
            pagerView.transformer = FSPagerViewTransformer(type: type)
            switch type {
            case .crossFading, .zoomOut, .depth:
                pagerView.itemSize = FSPagerView.automaticSize
                pagerView.decelerationDistance = 1
            case .linear, .overlap:
                let transform = CGAffineTransform(scaleX: 0.6, y: 0.75)
                pagerView.itemSize = pagerView.frame.size.applying(transform)
                pagerView.decelerationDistance = FSPagerView.automaticDistance
            case .ferrisWheel, .invertedFerrisWheel:
                pagerView.itemSize = CGSize(width: 180, height: 140)
                pagerView.decelerationDistance = FSPagerView.automaticDistance
            case .coverFlow:
                pagerView.itemSize = CGSize(width: 220, height: 170)
                pagerView.decelerationDistance = FSPagerView.automaticDistance
            case .cubic:
                let transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                pagerView.itemSize = pagerView.frame.size.applying(transform)
                pagerView.decelerationDistance = 1
            }
        }
    }

    @IBOutlet var tableView: UITableView!
    @IBOutlet var pagerView: FSPagerView! {
        didSet {
            pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
            typeIndex = 0
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let index = typeIndex
        typeIndex = index // Manually trigger didSet
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    @available(iOS 2.0, *)
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return transformerNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = transformerNames[indexPath.row]
        cell.accessoryType = indexPath.row == typeIndex ? .checkmark : .none
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        typeIndex = indexPath.row
        if let visibleRows = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: visibleRows, with: .automatic)
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        return "Transformers"
    }

    // MARK: - FSPagerViewDataSource

    public func numberOfItems(in _: FSPagerView) -> Int {
        return imageNames.count
    }

    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! FSPagerViewCell
        cell.imageView?.image = UIImage(named: imageNames[index])
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        return cell
    }

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
    }
}
