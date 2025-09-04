import XCTest
@testable import MediFastApp

final class TimeMathTests: XCTestCase {
    func testDurationAcrossMidnight_isOneHour() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)! // stable

        let start = cal.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 23, minute: 30))!
        let end = cal.date(from: DateComponents(year: 2024, month: 1, day: 2, hour: 0, minute: 30))!

        let diff = end.timeIntervalSince(start)
        XCTAssertEqual(diff, 3600, accuracy: 0.5)
    }

    func testFormattingOver24Hours_hms() throws {
        // 95h 59m 7s
        let seconds = TimeInterval(95 * 3600 + 59 * 60 + 7)
        XCTAssertEqual(TimeFormatter.hms(seconds), "95:59:07")
    }

    func testFormattingMinutesSeconds() throws {
        let seconds = TimeInterval(59 * 60 + 59)
        XCTAssertEqual(TimeFormatter.ms(seconds), "59:59")
    }
}

