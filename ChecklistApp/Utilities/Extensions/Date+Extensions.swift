import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeDescription: String {
        let time = formatted(date: .omitted, time: .shortened)
        if isToday {
            return L10n.todayPrefix(time: time)
        } else if isYesterday {
            return L10n.yesterdayPrefix(time: time)
        } else {
            return formatted(date: .abbreviated, time: .shortened)
        }
    }
}
