//
//  BasicExampleViewController.swift
//  FSPagerViewExample
//
//  Created by Wenchao Ding on 17/12/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

import UIKit

class BasicExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSPagerViewDataSource, FSPagerViewDelegate {
    fileprivate let sectionTitles = ["Configurations", "Decelaration Distance", "Item Size", "Interitem Spacing", "Number Of Items"]
    fileprivate let configurationTitles = ["Automatic sliding", "Infinite"]
    fileprivate let decelerationDistanceOptions = ["Automatic", "1", "2"]
    fileprivate let imageNames = ["1.jpg", "2.jpg", "3.jpg", "4.jpg", "5.jpg", "6.jpg", "7.jpg"]
    fileprivate var numberOfItems = 7

    @IBOutlet var tableView: UITableView!
    @IBOutlet var pagerView: FSPagerView! {
        didSet {
            pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
            pagerView.itemSize = FSPagerView.automaticSize
        }
    }

    @IBOutlet var pageControl: FSPageControl! {
        didSet {
            pageControl.numberOfPages = imageNames.count
            pageControl.contentHorizontalAlignment = .right
            pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        return sectionTitles.count
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return configurationTitles.count
        case 1:
            return decelerationDistanceOptions.count
        case 2, 3, 4:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // Configurations
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            cell.textLabel?.text = configurationTitles[indexPath.row]
            if indexPath.row == 0 {
                // Automatic Sliding
                cell.accessoryType = pagerView.automaticSlidingInterval > 0 ? .checkmark : .none
            } else if indexPath.row == 1 {
                // IsInfinite
                cell.accessoryType = pagerView.isInfinite ? .checkmark : .none
            }
            return cell
        case 1:
            // Decelaration Distance
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            cell.textLabel?.text = decelerationDistanceOptions[indexPath.row]
            switch indexPath.row {
            case 0:
                cell.accessoryType = pagerView.decelerationDistance == FSPagerView.automaticDistance ? .checkmark : .none
            case 1:
                cell.accessoryType = pagerView.decelerationDistance == 1 ? .checkmark : .none
            case 2:
                cell.accessoryType = pagerView.decelerationDistance == 2 ? .checkmark : .none
            default:
                break
            }
            return cell
        case 2:
            // Item Spacing
            let cell = tableView.dequeueReusableCell(withIdentifier: "slider_cell")!
            let slider = cell.contentView.subviews.first as! UISlider
            slider.tag = 1
            slider.value = {
                let scale: CGFloat = self.pagerView.itemSize.width / self.pagerView.frame.width
                let value: CGFloat = (0.5 - scale) * 2
                return Float(value)
            }()
            slider.isContinuous = true
            return cell
        case 3:
            // Interitem Spacing
            let cell = tableView.dequeueReusableCell(withIdentifier: "slider_cell")!
            let slider = cell.contentView.subviews.first as! UISlider
            slider.tag = 2
            slider.value = Float(pagerView.interitemSpacing / 20.0)
            slider.isContinuous = true
            return cell
        case 4:
            // Number Of Items
            let cell = tableView.dequeueReusableCell(withIdentifier: "slider_cell")!
            let slider = cell.contentView.subviews.first as! UISlider
            slider.tag = 3
            slider.minimumValue = 1.0 / 7
            slider.maximumValue = 1.0
            slider.value = Float(numberOfItems) / 7.0
            slider.isContinuous = false
            return cell
        default:
            break
        }
        return tableView.dequeueReusableCell(withIdentifier: "cell")!
    }

    // MARK: - UITableViewDelegate

    func tableView(_: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 || indexPath.section == 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 { // Automatic Sliding
                pagerView.automaticSlidingInterval = 3.0 - pagerView.automaticSlidingInterval
            } else if indexPath.row == 1 { // IsInfinite
                pagerView.isInfinite = !pagerView.isInfinite
            }
            tableView.reloadSections([indexPath.section], with: .automatic)
        case 1:
            switch indexPath.row {
            case 0:
                pagerView.decelerationDistance = FSPagerView.automaticDistance
            case 1:
                pagerView.decelerationDistance = 1
            case 2:
                pagerView.decelerationDistance = 2
            default:
                break
            }
            tableView.reloadSections([indexPath.section], with: .automatic)
        default:
            break
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 40 : 20
    }

    // MARK: - FSPagerView DataSource

    public func numberOfItems(in _: FSPagerView) -> Int {
        return numberOfItems
    }

    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! FSPagerViewCell
        cell.imageView?.image = UIImage(named: imageNames[index])
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        cell.textLabel?.text = index.description + index.description
        return cell
    }

    // MARK: - FSPagerView Delegate

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
    }

    func pagerViewWillEndDragging(_: FSPagerView, targetIndex: Int) {
        pageControl.currentPage = targetIndex
    }

    func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        switch sender.tag {
        case 1:
            let newScale = 0.5 + CGFloat(sender.value) * 0.5 // [0.5 - 1.0]
            pagerView.itemSize = pagerView.frame.size.applying(CGAffineTransform(scaleX: newScale, y: newScale))
        case 2:
            pagerView.interitemSpacing = CGFloat(sender.value) * 20 // [0 - 20]
        case 3:
            numberOfItems = Int(roundf(sender.value * 7.0))
            pageControl.numberOfPages = numberOfItems
            pagerView.reloadData()
        default:
            break
        }
    }
}
