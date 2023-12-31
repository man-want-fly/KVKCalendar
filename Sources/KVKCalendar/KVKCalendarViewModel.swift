//
//  KVKCalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 5/8/23.
//

import Foundation
import SwiftUI
import Combine

class KVKCalendarViewModel: ObservableObject {
    
    var data: CalendarData
    @Published public var type: CalendarType
    @ObservedObject var weekData: WeekData
    @ObservedObject var dayData: WeekData
    @Published public var date: Date
    
    private var cancellable: Set<AnyCancellable> = []
    
    init(date: Date,
         events: [KVKCalendar.Event],
         years: Int = 4,
         style: Style,
         type: CalendarType = .week) {
        self.date = date
        data = CalendarData(date: date,
                            years: years,
                            style: style)
        weekData = WeekData(data: data, events: events)
        dayData = WeekData(data: data, type: .day, events: events)
        self.type = type
        
        weekData.$date
            .removeDuplicates()
            .assign(to: \.date, on: self)
            .store(in: &cancellable)
        dayData.$date
            .removeDuplicates()
            .assign(to: \.date, on: self)
            .store(in: &cancellable)
    }
    
    func setDate(_ date: Date) {
        weekData.date = date
    }
    
    func setEvents(_ events: [Event]) {
        weekData.events = events
    }
    
}
