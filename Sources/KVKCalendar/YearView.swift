//
//  YearView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 15.0, *)
struct YearNewView: View {
    
    @ObservedObject var data: YearData
    
    private var style: Style {
        data.style
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]
    
    init(data: CalendarData, style: Style) {
        self.data = YearData(data: data, date: data.date, style: style)
    }
    
    var body: some View {
        ScrollViewReader { (proxy) in
            ScrollView {
                LazyVGrid(columns: columns, pinnedViews: .sectionHeaders) {
                    ForEach(data.sections) { (section) in
                        Section {
                            ForEach(section.months) { (month) in
                                Button {
                                    data.handleSelectedDate(month.date)
                                } label: {
                                    YearMonthView(month: month, style: style, selectedDate: data.date)
                                }
                                .tint(.black)
                            }
                        } header: {
                            HStack {
                                Text(section.date.titleForLocale(style.locale, formatter: style.year.titleFormatter))
                                    .foregroundColor(Date().kvkYear == section.date.kvkYear ? .red : Color(uiColor: style.year.colorTitleHeader))
                                    .font(Font(style.year.fontTitleHeader))
                                    .padding(5)
                                Spacer()
                            }
                            .background(.thickMaterial)
                            .padding([.top, .bottom], 10)
                        }
                        .id(section.date.kvkYear)
                    }
                }
            }
            .task {
                withAnimation {
                    proxy.scrollTo(data.date.kvkYear, anchor: .top)
                }
            }
        }
    }
    
}

@available(iOS 15.0, *)
struct YearNewView_Previews: PreviewProvider {
    
    static var previews: some View {
        let style = Style()
        let monthData = MonthData(parameters: .init(data: CalendarData(date: Date(), years: 2, style: style), startDay: style.startWeekDay, calendar: style.calendar, style: style))
        return Group {
            YearNewView(data: monthData.data, style: Style())
            YearNewView(data: monthData.data, style: Style())
                .preferredColorScheme(.dark)
        }
    }
    
}

@available(iOS 15.0, *)
private struct YearMonthView: View {
    
    var month: Month
    var style: Style
    var selectedDate: Date
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    private var daySize: CGSize {
        Platform.currentInterface == .phone ? CGSize(width: 15, height: 15) : CGSize(width: 30, height: 30)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(month.name)
                    .font(Font(style.year.fontTitle))
                Spacer()
            }
            WeekTitlesView(style: style)
            LazyVGrid(columns: columns) {
                ForEach(month.days) { (day) in
                    if let date = day.date, day.type != .empty {
                        VStack(alignment: .center) {
                            Text("\(date.kvkDay)")
                                .foregroundColor(getCurrentTxtColor(date, selectedDay: selectedDate))
                                .font(Font(style.year.fontDayTitle))
                                .minimumScaleFactor(0.5)
                                .frame(width: daySize.width, height: daySize.height)
                                .fixedSize()
                        }
                        .background(getCurrentBgTxtColor(date, selectedDay: selectedDate))
                        .clipShape(Circle())
                    } else {
                        Text("")
                    }
                }
            }
            Spacer()
        }
    }
    
    private func getCurrentTxtColor(_ day: Date,
                                    selectedDay: Date) -> Color {
        if day.kvkIsEqual(selectedDay) {
            return .white
        } else if day.isWeekend {
            return Color(uiColor: style.week.colorWeekendDate)
        } else {
            return .black
        }
    }
    
    private func getCurrentBgTxtColor(_ day: Date,
                                      selectedDay: Date) -> Color {
        if day.kvkIsEqual(selectedDay) && day.kvkIsEqual(Date()) {
            return .red
        } else if day.kvkIsEqual(selectedDay) {
            return .black
        } else {
            return .clear
        }
    }
    
}

@available(iOS 15.0, *)
struct WeekTitlesView: View, WeekPreparing {
    
    private var days: [Date] = []
    private let style: Style
    private let formatter: DateFormatter
    private let font: UIFont
    
    init(style: Style, formatter: DateFormatter? = nil, font: UIFont? = nil) {
        self.style = style
        self.formatter = formatter ?? style.year.weekdayFormatter
        self.font = font ?? style.year.weekFont
        days = getWeekDays(style: style)
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(days, id: \.self) { (day) in
                Text(day.titleForLocale(style.locale, formatter: formatter))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(getTxtColor(day, style: style))
                    .font(Font(font))
                    .background(getTxtBgColor(day, style: style))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func getTxtColor(_ day: Date, style: Style) -> Color {
        if day.isWeekend {
            return Color(uiColor: style.week.colorWeekendDate)
        } else if day.isWeekday {
            return Color(uiColor: style.week.colorDate)
        } else {
            return .clear
        }
    }
    
    private func getTxtBgColor(_ day: Date, style: Style) -> Color {
        if day.isWeekend {
            return Color(uiColor: style.week.colorWeekendBackground)
        } else if day.isWeekday {
            return Color(uiColor: style.week.colorWeekdayBackground)
        } else {
            return .clear
        }
    }
    
}

@available(iOS 15.0, *)
struct WeekSimpleView_Previews: PreviewProvider {
    
    static var previews: some View {
        WeekTitlesView(style: Style())
    }
    
}

final class YearView: UIView {
    private var data: YearData
    private var collectionView: UICollectionView?
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    private var layout = UICollectionViewFlowLayout()
    
    private func scrollDirection(month: Int) -> UICollectionView.ScrollPosition {
        switch month {
        case 1...4:
            return .top
        case 5...8:
            return .centeredVertically
        default:
            return .bottom
        }
    }
    
    init(data: YearData, frame: CGRect? = nil) {
        self.data = data
        super.init(frame: frame ?? .zero)
    }
    
    func setDate(_ date: Date, animated: Bool) {
        data.date = date
        scrollToDate(date: date, animated: animated)
        collectionView?.reloadData()
    }
    
    private func createCollectionView(frame: CGRect, style: YearStyle) -> (view: UICollectionView, customView: Bool) {
        if let customCollectionView = dataSource?.willDisplayCollectionView(frame: frame, type: .year) {
            if customCollectionView.delegate == nil {
                customCollectionView.delegate = self
            }
            if customCollectionView.dataSource == nil {
                customCollectionView.dataSource = self
            }
            return (customCollectionView, true)
        }
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = style.colorBackground
        collection.isPagingEnabled = style.isPagingEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return (collection, false)
    }
    
    private func scrollToDate(date: Date, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.sections.firstIndex(where: { $0.date.kvkYear == date.kvkYear }) {
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                  at: self.scrollDirection(month: date.kvkMonth),
                                                  animated: animated)
            }
        }
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let a = indexPath.item / data.itemsInPage
            let b = indexPath.item / data.rowsInPage - a * data.columnsInPage
            let c = indexPath.item % data.rowsInPage
            let newIdx = (c * data.columnsInPage + b) + a * data.itemsInPage
            return IndexPath(row: newIdx, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension YearView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            data.style
        }
        set {
            data.style = newValue
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.sections.firstIndex(where: { $0.date.kvkYear == self.data.date.kvkYear }) {
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                  at: self.scrollDirection(month: self.data.date.kvkMonth),
                                                  animated: false)
            }
        }
        
        collectionView?.reloadData()
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
    }
    
    func setUI(reload: Bool = false) {
        backgroundColor = data.style.year.colorBackground
        subviews.forEach { $0.removeFromSuperview() }
        layout.scrollDirection = data.style.year.scrollDirection
        
        switch data.style.year.scrollDirection {
        case .horizontal:
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
        case .vertical:
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 5
        @unknown default:
            fatalError()
        }
        
        collectionView = nil
        let result = createCollectionView(frame: frame, style: data.style.year)
        collectionView = result.view
        
        if let viewTemp = collectionView {
            addSubview(viewTemp)
            
            if !result.customView {
                viewTemp.translatesAutoresizingMaskIntoConstraints = false
                let top = viewTemp.topAnchor.constraint(equalTo: topAnchor)
                let bottom = viewTemp.bottomAnchor.constraint(equalTo: bottomAnchor)
                let left = viewTemp.leftAnchor.constraint(equalTo: leftAnchor)
                let right = viewTemp.rightAnchor.constraint(equalTo: rightAnchor)
                NSLayoutConstraint.activate([top, bottom, left, right])
            }
        }
    }
}

extension YearView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        data.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.sections[section].months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let month = data.sections[index.section].months[index.row]
        
        if let cell = dataSource?.dequeueCell(parameter: .init(date: month.date, type: nil), type: .year, view: collectionView, indexPath: index) as? UICollectionViewCell {
            return cell
        } else {
            return collectionView.kvkDequeueCell(indexPath: index) { (cell: YearCell) in
                cell.style = data.style
                cell.selectDate = data.date
                cell.title = month.name
                cell.date = month.date
                cell.days = month.days
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let date = data.sections[index.section].date
        
        if let headerView = dataSource?.dequeueHeader(date: date, type: .year, view: collectionView, indexPath: index) as? UICollectionReusableView {
            return headerView
        } else {
            return collectionView.kvkDequeueView(indexPath: index) { (headerView: YearHeaderView) in
                headerView.style = data.style
                headerView.date = date
            }
        }
    }
}

extension YearView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard data.style.year.autoSelectionDateWhenScrolling else { return }
        
        let cells = collectionView?.indexPathsForVisibleItems ?? []
        let dates = cells.compactMap { data.sections[$0.section].months[$0.row].date }
        delegate?.didDisplayEvents([], dates: dates, type: .year)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let date = data.sections[index.section].months[index.row].date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let newDate = formatter.date(from: "\(data.date.kvkDay).\(date.kvkMonth).\(date.kvkYear)")
        data.date = newDate ?? Date()
        collectionView.reloadData()
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectDates([newDate].compactMap({ $0 }), type: data.style.year.selectCalendarType, frame: frame)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        if let size = delegate?.sizeForCell(data.sections[index.section].months[index.row].date, type: .year) {
            return size
        }
        
        var width: CGFloat
        var height = collectionView.frame.height
        
        if height > 0 {
            height -= data.style.year.heightTitleHeader
        }
        
        if Platform.currentInterface != .phone {
            width = collectionView.frame.width / 4
            height /= 3
        } else {
            width = collectionView.frame.width / 3
            height /= 4
        }
        
        if width > 0 {
            width -= layout.minimumInteritemSpacing
        }
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: IndexPath(row: 0, section: section))
        let date = data.sections[index.section].date
        
        if let size = delegate?.sizeForHeader(date, type: .year) {
            return size
        } else {
            switch data.style.year.scrollDirection {
            case .horizontal:
                return .zero
            case .vertical:
                return CGSize(width: collectionView.bounds.width, height: data.style.year.heightTitleHeader)
            @unknown default:
                fatalError()
            }
        }
    }
}

#endif
