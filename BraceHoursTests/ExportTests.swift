import XCTest
import SwiftData
import PDFKit
@testable import BraceHours

@MainActor
final class ExportTests: XCTestCase {
    private func sampleContainer() throws -> ModelContainer {
        let schema = Schema([Profile.self, WearSession.self, SkinCheck.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        SampleData.insert(into: container.mainContext)
        return container
    }

    func testReportRendersWithSampleData() throws {
        let container = try sampleContainer()
        let context = container.mainContext
        let profile = try XCTUnwrap(try context.fetch(FetchDescriptor<Profile>()).first)
        let sessions = try context.fetch(FetchDescriptor<WearSession>())
        let checks = try context.fetch(FetchDescriptor<SkinCheck>())
        XCTAssertGreaterThan(sessions.count, 80)

        let start = Calendar.current.date(byAdding: .day, value: -29, to: .now)!
        let url = try ReportExporter.export(profile: profile, sessions: sessions, skinChecks: checks, from: start)
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThanOrEqual(document.pageCount, 2)
        let text = (0..<document.pageCount).compactMap { document.page(at: $0)?.string }.joined()
        XCTAssertTrue(text.contains("Ava"))
        XCTAssertTrue(text.contains("Days at or above goal"))
        XCTAssertTrue(text.contains("Hips"))
        XCTAssertTrue(text.contains("not a clinical measurement"))
    }

    func testDailyCSV() {
        let totals = [WearMath.DayTotal(day: Date(timeIntervalSince1970: 0), seconds: 18.5 * 3600), WearMath.DayTotal(day: Date(timeIntervalSince1970: 86_400), seconds: 10 * 3600)]
        let csv = CSVExporter.dailyCSV(totals, goalHours: 18)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[1].hasSuffix("\"18.50\",\"18.0\",\"yes\""))
        XCTAssertTrue(lines[2].hasSuffix("\"10.00\",\"18.0\",\"no\""))
    }
}
