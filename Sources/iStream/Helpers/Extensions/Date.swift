//
//  Date.swift
//  iStream
//
//  Created by Conrad Felgentreff on 30.04.22.
//

import Foundation

extension Date {
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(for: self) ?? "\(self)"
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(for: self) ?? "\(self)"
    }
    
    // MARK: https://stackoverflow.com/questions/53356392/how-to-get-day-and-month-from-date-type-swift-4
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
    func isSameDay(as date: Date) -> Bool {
        self.get(.day) == date.get(.day) && self.get(.month) == date.get(.month) && self.get(.year) == date.get(.year)
    }
}
