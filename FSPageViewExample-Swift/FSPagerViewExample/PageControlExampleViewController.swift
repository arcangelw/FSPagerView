//
//  PageControlExampleViewController.swift
//  FSPagerViewExample
//
//  Created by Wenchao Ding on 17/01/2017.
//  Copyright © 2017 Wenchao Ding. All rights reserved.
//

import UIKit

class PageControlExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSPagerViewDataSource, FSPagerViewDelegate {
    fileprivate let imageNames = ["1.jpg", "2.jpg", "3.jpg", "4.jpg", "5.jpg", "6.jpg", "7.jpg"]
    fileprivate let pageControlStyles = ["Default", "Ring", "UIImage", "UIBezierPath - Star", "UIBezierPath - Heart"]
    fileprivate let pageControlAlignments = ["Right", "Center", "Left"]
    fileprivate let sectionTitles = ["Style", "Item Spacing", "Interitem Spacing", "Horizontal Alignment"]

    fileprivate var styleIndex = 0 {
        didSet {
            // Clean up
            pageControl.setStrokeColor(nil, for: .normal)
            pageControl.setStrokeColor(nil, for: .selected)
            pageControl.setFillColor(nil, for: .normal)
            pageControl.setFillColor(nil, for: .selected)
            pageControl.setImage(nil, for: .normal)
            pageControl.setImage(nil, for: .selected)
            pageControl.setPath(nil, for: .normal)
            pageControl.setPath(nil, for: .selected)
            switch styleIndex {
            case 0:
                // Default
                break
            case 1:
                // Ring
                pageControl.setStrokeColor(.green, for: .normal)
                pageControl.setStrokeColor(.green, for: .selected)
                pageControl.setFillColor(.green, for: .selected)
            case 2:
                // Image
                pageControl.setImage(UIImage(named: "icon_footprint"), for: .normal)
                pageControl.setImage(UIImage(named: "icon_cat"), for: .selected)
            case 3:
                // UIBezierPath - Star
                pageControl.setStrokeColor(.yellow, for: .normal)
                pageControl.setStrokeColor(.yellow, for: .selected)
                pageControl.setFillColor(.yellow, for: .selected)
                pageControl.setPath(starPath, for: .normal)
                pageControl.setPath(starPath, for: .selected)
            case 4:
                // UIBezierPath - Heart
                let color = UIColor(red: 255 / 255.0, green: 102 / 255.0, blue: 255 / 255.0, alpha: 1.0)
                pageControl.setStrokeColor(color, for: .normal)
                pageControl.setStrokeColor(color, for: .selected)
                pageControl.setFillColor(color, for: .selected)
                pageControl.setPath(heartPath, for: .normal)
                pageControl.setPath(heartPath, for: .selected)
            default:
                break
            }
        }
    }

    fileprivate var alignmentIndex = 0 {
        didSet {
            pageControl.contentHorizontalAlignment = [.right, .center, .left][alignmentIndex]
        }
    }

    // ⭐️
    fileprivate var starPath: UIBezierPath {
        let width = pageControl.itemSpacing
        let height = pageControl.itemSpacing
        let starPath = UIBezierPath()
        starPath.move(to: CGPoint(x: width * 0.5, y: 0))
        starPath.addLine(to: CGPoint(x: width * 0.677, y: height * 0.257))
        starPath.addLine(to: CGPoint(x: width * 0.975, y: height * 0.345))
        starPath.addLine(to: CGPoint(x: width * 0.785, y: height * 0.593))
        starPath.addLine(to: CGPoint(x: width * 0.794, y: height * 0.905))
        starPath.addLine(to: CGPoint(x: width * 0.5, y: height * 0.8))
        starPath.addLine(to: CGPoint(x: width * 0.206, y: height * 0.905))
        starPath.addLine(to: CGPoint(x: width * 0.215, y: height * 0.593))
        starPath.addLine(to: CGPoint(x: width * 0.025, y: height * 0.345))
        starPath.addLine(to: CGPoint(x: width * 0.323, y: height * 0.257))
        starPath.close()
        return starPath
    }

    // ❤️
    fileprivate var heartPath: UIBezierPath {
        let width = pageControl.itemSpacing
        let height = pageControl.itemSpacing
        let heartPath = UIBezierPath()
        heartPath.move(to: CGPoint(x: width * 0.5, y: height))
        heartPath.addCurve(
            to: CGPoint(x: 0, y: height * 0.25),
            controlPoint1: CGPoint(x: width * 0.5, y: height * 0.75),
            controlPoint2: CGPoint(x: 0, y: height * 0.5)
        )
        heartPath.addArc(
            withCenter: CGPoint(x: width * 0.25, y: height * 0.25),
            radius: width * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        heartPath.addArc(
            withCenter: CGPoint(x: width * 0.75, y: height * 0.25),
            radius: width * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        heartPath.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            controlPoint1: CGPoint(x: width, y: height * 0.5),
            controlPoint2: CGPoint(x: width * 0.5, y: height * 0.75)
        )
        heartPath.close()
        return heartPath
    }

    @IBOutlet var tableView: UITableView!
    @IBOutlet var pagerView: FSPagerView! {
        didSet {
            pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        }
    }

    @IBOutlet var pageControl: FSPageControl! {
        didSet {
            pageControl.numberOfPages = imageNames.count
            pageControl.contentHorizontalAlignment = .right
            pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            pageControl.hidesForSinglePage = true
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        return sectionTitles.count
    }

    @available(iOS 2.0, *)
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return pageControlStyles.count
        case 1, 2:
            return 1
        case 3:
            return pageControlAlignments.count
        default:
            break
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            cell.textLabel?.text = pageControlStyles[indexPath.row]
            cell.accessoryType = styleIndex == indexPath.row ? .checkmark : .none
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "slider_cell")!
            let slider = cell.contentView.subviews.first as! UISlider
            slider.tag = indexPath.section
            slider.value = Float((pageControl.itemSpacing - 6.0) / 10.0)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "slider_cell")!
            let slider = cell.contentView.subviews.first as! UISlider
            slider.tag = indexPath.section
            slider.value = Float((pageControl.interitemSpacing - 6.0) / 10.0)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            cell.textLabel?.text = pageControlAlignments[indexPath.row]
            cell.accessoryType = alignmentIndex == indexPath.row ? .checkmark : .none
            return cell
        default:
            break
        }
        return tableView.dequeueReusableCell(withIdentifier: "cell")!
    }

    // MARK: - UITableViewDelegate

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func tableView(_: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return [0, 3].contains(indexPath.section) // 0 or 3
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            styleIndex = indexPath.row
            tableView.reloadSections([indexPath.section], with: .automatic)
        case 3:
            alignmentIndex = indexPath.row
            tableView.reloadSections([indexPath.section], with: .automatic)
        default:
            break
        }
    }

    // MARK: - FSPagerViewDataSource

    func numberOfItems(in _: FSPagerView) -> Int {
        return imageNames.count
    }

    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! FSPagerViewCell
        cell.imageView?.image = UIImage(named: imageNames[index])
        cell.imageView?.contentMode = .scaleAspectFill
        return cell
    }

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
    }

    // MARK: - FSPagerViewDelegate

    func pagerViewWillEndDragging(_: FSPagerView, targetIndex: Int) {
        pageControl.currentPage = targetIndex
    }

    // MARK: - Target Actions

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        switch sender.tag {
        case 1:
            pageControl.itemSpacing = 6.0 + CGFloat(sender.value * 10.0) // [6 - 16]
            // Redraw UIBezierPath
            if [3, 4].contains(styleIndex) {
                let index = styleIndex
                styleIndex = index
            }
        case 2:
            pageControl.interitemSpacing = 6.0 + CGFloat(sender.value * 10.0) // [6 - 16]
        default:
            break
        }
    }
}
