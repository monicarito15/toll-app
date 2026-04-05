//
//  RushHourTests.swift
//  toll-appTests
//
//  Tests for Date+RushHour extension (Norwegian rush hour detection)

import Testing
import Foundation
@testable import toll_app

struct RushHourTests {

    // Morning Rush Hour (06:30 – 09:00, weekdays)

    @Test func morningRushStart_isRushHour() {
        #expect(makeDate(weekday: .monday, hour: 6, minute: 30).isRushHour() == true)
    }

    @Test func morningRushMiddle_isRushHour() {
        #expect(makeDate(weekday: .wednesday, hour: 7, minute: 45).isRushHour() == true)
    }

    @Test func morningRushEnd_isNotRushHour() {
        // 09:00 is exclusive
        #expect(makeDate(weekday: .tuesday, hour: 9, minute: 0).isRushHour() == false)
    }

    @Test func beforeMorningRush_isNotRushHour() {
        #expect(makeDate(weekday: .thursday, hour: 6, minute: 29).isRushHour() == false)
    }

    // Afternoon Rush Hour (15:00 – 17:00, weekdays)

    @Test func afternoonRushStart_isRushHour() {
        #expect(makeDate(weekday: .friday, hour: 15, minute: 0).isRushHour() == true)
    }

    @Test func afternoonRushMiddle_isRushHour() {
        #expect(makeDate(weekday: .monday, hour: 16, minute: 30).isRushHour() == true)
    }

    @Test func afternoonRushEnd_isNotRushHour() {
        // 17:00 is exclusive
        #expect(makeDate(weekday: .friday, hour: 17, minute: 0).isRushHour() == false)
    }

    @Test func betweenRushHours_isNotRushHour() {
        #expect(makeDate(weekday: .wednesday, hour: 12, minute: 0).isRushHour() == false)
    }

    // Weekends (no rush hour)

    @Test func saturday_isNotRushHour() {
        #expect(makeDate(weekday: .saturday, hour: 8, minute: 0).isRushHour() == false)
    }

    @Test func sunday_isNotRushHour() {
        #expect(makeDate(weekday: .sunday, hour: 16, minute: 0).isRushHour() == false)
    }

    //rushHourTimeRange

    @Test func morningRange_returnsString() {
        let date = makeDate(weekday: .monday, hour: 7, minute: 0)
        #expect(date.rushHourTimeRange() == "6:30 - 9:00")
    }

    @Test func afternoonRange_returnsString() {
        let date = makeDate(weekday: .tuesday, hour: 15, minute: 30)
        #expect(date.rushHourTimeRange() == "15:00 - 17:00")
    }

    @Test func outsideRush_rangeIsNil() {
        let date = makeDate(weekday: .wednesday, hour: 11, minute: 0)
        #expect(date.rushHourTimeRange() == nil)
    }

    // Helpers

    private enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }

    // Builds a Date for a specific weekday/time in the current week using the local calendar.
    private func makeDate(weekday: Weekday, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.weekday = weekday.rawValue
        components.hour = hour
        components.minute = minute
        components.second = 0
        // Use a fixed reference week to avoid flakiness
        components.yearForWeekOfYear = 2026
        components.weekOfYear = 14
        return Calendar.current.date(from: components)!
    }
}
