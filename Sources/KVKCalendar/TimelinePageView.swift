//
//  TimelinePageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 05.12.2020.
//

#if os(iOS)

import UIKit

final class TimelinePageView: UIView {
    
    enum SwitchPageType: Int {
        case next, previous
        
        var direction: UIPageViewController.NavigationDirection {
            switch self {
            case .next:
                return .forward
            case .previous:
                return .reverse
            }
        }
    }
    
    enum AddNewTimelineViewType: Int {
        case begin, end
    }
    
    private var pages: [Int: TimelineView]
    private var currentIndex: Int
    private let maxLimit: UInt
    
    var didSwitchTimelineView: ((TimelineView?, SwitchPageType) -> Void)?
    var willDisplayTimelineView: ((TimelineView, SwitchPageType) -> Void)?
    
    var timelineView: TimelineView? {
        pages[currentIndex]
    }
    
    var isPagingEnabled = true
    
    private let mainPageView: UIPageViewController = {
        let pageView = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        return pageView
    }()
    
    init(maxLimit: UInt, pages: [TimelineView], frame: CGRect) {
        self.maxLimit = maxLimit
        self.pages = pages.enumerated().reduce([:], { (acc, item) -> [Int: TimelineView] in
            var accTemp = acc
            accTemp[item.offset] = item.element
            return accTemp
        })
        self.currentIndex = (pages.count / 2) - 1
        super.init(frame: frame)
        
        if !pages.isEmpty {
            let view = pages[currentIndex]
            let container = TimelineContainerVC(index: currentIndex, contentView: view)
            mainPageView.setViewControllers([container], direction: .forward, animated: false, completion: nil)
            addSubview(mainPageView.view)
            mainPageView.view.translatesAutoresizingMaskIntoConstraints = false
            
            let top = mainPageView.view.topAnchor.constraint(equalTo: topAnchor)
            let leading = mainPageView.view.leadingAnchor.constraint(equalTo: leadingAnchor)
            let trailing = mainPageView.view.trailingAnchor.constraint(equalTo: trailingAnchor)
            let bottom = mainPageView.view.bottomAnchor.constraint(equalTo: bottomAnchor)
            NSLayoutConstraint.activate([top, leading, trailing, bottom])
        }
        
        mainPageView.dataSource = self
        mainPageView.delegate = self
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        pages.forEach { $0.value.updateStyle(style, force: force) }
    }
    
    func reloadPages(excludeCurrentPage: Bool = false) {
        var items: [Int: TimelineView]
        if excludeCurrentPage {
            items = pages
            items.removeValue(forKey: currentIndex)
        } else {
            items = pages
        }
        items.forEach { $0.value.reloadTimeline() }
    }
    
    func removeAll(excludeCurrentPage: Bool = false) {
        if excludeCurrentPage {
            pages = pages.filter { $0.key == currentIndex }
        } else {
            pages.removeAll()
        }
    }
    
    func reloadScale(_ scale: CGFloat, excludeCurrentPage: Bool = false) {
        var items: [Int: TimelineView]
        if excludeCurrentPage {
            items = pages
            items.removeValue(forKey: currentIndex)
        } else {
            items = pages
        }
        
        items.forEach {
            $0.value.paramaters.scale = scale
            $0.value.reloadTimeline()
        }
    }
    
    func reloadCachedControllers() {
        pages = pages.reduce([:], { (acc, item) -> [Int: TimelineView] in
            var accTemp = acc
            item.value.reloadFrame(CGRect(origin: .zero, size: bounds.size))
            accTemp[item.key] = item.value
            return accTemp
        })
        mainPageView.dataSource = nil
        mainPageView.dataSource = self
    }
    
    func addNewTimelineView(_ timeline: TimelineView, to: AddNewTimelineViewType) {
        switch to {
        case .end:
            pages[currentIndex + 1] = timeline
            
            if pages.count > maxLimit, let firstKey = pages.max(by: { $0.key > $1.key }) {
                pages.removeValue(forKey: firstKey.key)
            }
        case .begin:
            pages[currentIndex - 1] = timeline
            
            if pages.count > maxLimit, let lastKey = pages.max(by: { $0.key < $1.key }) {
                pages.removeValue(forKey: lastKey.key)
            }
        }
    }
    
    func changePage(_ type: SwitchPageType) {
        switch type {
        case .previous:
            currentIndex -= 1
        case .next:
            currentIndex += 1
        }
        
        guard let newTimelineView = pages[currentIndex] else { return }
        
        willDisplayTimelineView?(newTimelineView, type)
        let container = TimelineContainerVC(index: currentIndex, contentView: newTimelineView)
        mainPageView.setViewControllers([container], direction: type.direction, animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelinePageView: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let vc = pendingViewControllers.first as? TimelineContainerVC, let contentOffset = timelineView?.contentOffset else { return }
        
        let pendingTimelineView = pages[vc.index]
        pendingTimelineView?.contentOffset = contentOffset
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelineContainerVC)?.index, isPagingEnabled else { return nil }
        
        newIndex -= 1
        guard let newTimelineView = pages[newIndex] else { return nil }
        
        if let scale = timelineView?.paramaters.scale, newTimelineView.paramaters.scale != scale {
            newTimelineView.paramaters.scale = scale
        }
        
        willDisplayTimelineView?(newTimelineView, .previous)
        let container = TimelineContainerVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelineContainerVC)?.index, isPagingEnabled else { return nil }
        
        newIndex += 1
        guard let newTimelineView = pages[newIndex] else { return nil }
        
        if let scale = timelineView?.paramaters.scale, newTimelineView.paramaters.scale != scale {
            newTimelineView.paramaters.scale = scale
        }
        
        willDisplayTimelineView?(newTimelineView, .next)
        let container = TimelineContainerVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = (pageViewController.viewControllers?.first as? TimelineContainerVC)?.index, completed else { return }
                
        let type: SwitchPageType
        if index > currentIndex {
            type = .next
            currentIndex = index
        } else {
            type = .previous
            currentIndex = index
        }
        
        didSwitchTimelineView?(timelineView, type)
    }
}

final class TimelinePageVC: UIPageViewController {
    
    enum SwitchPageType: Int {
        case next, previous
        
        var direction: UIPageViewController.NavigationDirection {
            switch self {
            case .next:
                return .forward
            case .previous:
                return .reverse
            }
        }
    }
    
    enum AddNewTimelineViewType: Int {
        case begin, end
    }
    
    private var pages: [Int: TimelineView]
    private var currentIndex: Int
    private let maxLimit: UInt
    
    var didSwitchTimelineView: ((TimelineView?, SwitchPageType) -> Void)?
    var willDisplayTimelineView: ((TimelineView, SwitchPageType) -> Void)?
    
    var timelineView: TimelineView? {
        pages[currentIndex]
    }
    
    var isPagingEnabled = true
    
    init(maxLimit: UInt, pages: [TimelineView]) {
        self.maxLimit = maxLimit
        self.pages = pages.enumerated().reduce([:], { (acc, item) -> [Int: TimelineView] in
            var accTemp = acc
            accTemp[item.offset] = item.element
            return accTemp
        })
        self.currentIndex = (pages.count / 2) - 1
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        
        if !pages.isEmpty {
            let view = pages[currentIndex]
            let container = TimelineContainerProxyVC(index: currentIndex, contentView: view)
            setViewControllers([container], direction: .forward, animated: false, completion: nil)
        }
        
        dataSource = self
        delegate = self
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        pages.forEach { $0.value.updateStyle(style, force: force) }
    }
    
    func reloadPages(excludeCurrentPage: Bool = false) {
        var items: [Int: TimelineView]
        if excludeCurrentPage {
            items = pages
            items.removeValue(forKey: currentIndex)
        } else {
            items = pages
        }
        items.forEach { $0.value.reloadTimeline() }
    }
    
    @available(iOS 16.0, *)
    func reloadPages(with params: TimelineViewWrapper.Parameters) {
        pages.forEach { $0.value.reloadTimeline(params: params) }
    }
    
    func removeAll(excludeCurrentPage: Bool = false) {
        if excludeCurrentPage {
            pages = pages.filter { $0.key == currentIndex }
        } else {
            pages.removeAll()
        }
    }
    
    func reloadScale(_ scale: CGFloat, excludeCurrentPage: Bool = false) {
        var items: [Int: TimelineView]
        if excludeCurrentPage {
            items = pages
            items.removeValue(forKey: currentIndex)
        } else {
            items = pages
        }
        
        items.forEach {
            $0.value.paramaters.scale = scale
            $0.value.reloadTimeline()
        }
    }
    
    func reloadCachedControllers() {
        pages = pages.reduce([:], { (acc, item) -> [Int: TimelineView] in
            var accTemp = acc
            //item.value.reloadFrame(CGRect(origin: .zero, size: bounds.size))
            accTemp[item.key] = item.value
            return accTemp
        })
        dataSource = nil
        dataSource = self
    }
    
    func addNewTimelineView(_ timeline: TimelineView, to: AddNewTimelineViewType) {
        switch to {
        case .end:
            pages[currentIndex + 1] = timeline
            
            if pages.count > maxLimit, let firstKey = pages.max(by: { $0.key > $1.key }) {
                pages.removeValue(forKey: firstKey.key)
            }
        case .begin:
            pages[currentIndex - 1] = timeline
            
            if pages.count > maxLimit, let lastKey = pages.max(by: { $0.key < $1.key }) {
                pages.removeValue(forKey: lastKey.key)
            }
        }
    }
    
    func changePage(_ type: SwitchPageType) {
        switch type {
        case .previous:
            currentIndex -= 1
        case .next:
            currentIndex += 1
        }
        
        guard let newTimelineView = pages[currentIndex] else { return }
        
        willDisplayTimelineView?(newTimelineView, type)
        let container = TimelineContainerProxyVC(index: currentIndex, contentView: newTimelineView)
        setViewControllers([container], direction: type.direction, animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelinePageVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let vc = pendingViewControllers.first as? TimelineContainerProxyVC, let contentOffset = timelineView?.contentOffset else { return }
        
        let pendingTimelineView = pages[vc.index]
        pendingTimelineView?.contentOffset = contentOffset
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelineContainerProxyVC)?.index, isPagingEnabled else { return nil }
        
        newIndex -= 1
        guard let newTimelineView = pages[newIndex] else { return nil }
        
        if let scale = timelineView?.paramaters.scale, newTimelineView.paramaters.scale != scale {
            newTimelineView.paramaters.scale = scale
        }
        
        willDisplayTimelineView?(newTimelineView, .previous)
        let container = TimelineContainerProxyVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelineContainerProxyVC)?.index, isPagingEnabled else { return nil }
        
        newIndex += 1
        guard let newTimelineView = pages[newIndex] else { return nil }
        
        if let scale = timelineView?.paramaters.scale, newTimelineView.paramaters.scale != scale {
            newTimelineView.paramaters.scale = scale
        }
        
        willDisplayTimelineView?(newTimelineView, .next)
        let container = TimelineContainerProxyVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = (pageViewController.viewControllers?.first as? TimelineContainerProxyVC)?.index, completed else { return }
                
        let type: SwitchPageType
        if index > currentIndex {
            type = .next
            currentIndex = index
        } else {
            type = .previous
            currentIndex = index
        }
        
        didSwitchTimelineView?(timelineView, type)
    }
}


#endif
