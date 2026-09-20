import XCTest
@testable import DynamicNotch

@MainActor
final class FileConverterDocumentConversionTests: XCTestCase {
    func testPagesPackageIsDetectedAsDocumentAndOffersDOCX() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DynamicNotch.FileConverterTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let pagesURL = directory.appendingPathComponent("Sample.pages", isDirectory: true)
        try FileManager.default.createDirectory(at: pagesURL, withIntermediateDirectories: true)

        let viewModel = FileConverterViewModel()
        TestLifetime.retain(viewModel)
        try viewModel.setFile(pagesURL)

        XCTAssertEqual(viewModel.item?.mediaKind, .document)
        XCTAssertEqual(viewModel.selectedFormat, .docx)
        XCTAssertTrue(viewModel.availableFormats.contains(.docx))
    }

    func testPagesFileIsDetectedAsDocumentEvenWhenStoredAsAFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DynamicNotch.FileConverterTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let pagesURL = directory.appendingPathComponent("Flat.pages")
        try Data("pages".utf8).write(to: pagesURL)

        let viewModel = FileConverterViewModel()
        TestLifetime.retain(viewModel)
        try viewModel.setFile(pagesURL)

        XCTAssertEqual(viewModel.item?.mediaKind, .document)
        XCTAssertEqual(viewModel.selectedFormat, .docx)
    }
}
