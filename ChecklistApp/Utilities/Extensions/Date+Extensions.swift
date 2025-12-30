import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeDescription: String {
        if isToday {
            return "今日 \(formatted(date: .omitted, time: .shortened))"
        } else if isYesterday {
            return "昨日 \(formatted(date: .omitted, time: .shortened))"
        } else {
            return formatted(date: .abbreviated, time: .shortened)
        }
    }
}
