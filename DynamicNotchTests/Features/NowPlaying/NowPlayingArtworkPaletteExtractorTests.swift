import XCTest
import AppKit
@testable import DynamicNotch

final class NowPlayingArtworkPaletteExtractorTests: XCTestCase {
    func testReturnsFallbackPaletteWhenArtworkIsMissing() {
        XCTAssertEqual(
            NowPlayingArtworkPaletteExtractor.extract(from: nil),
            .fallback
        )
    }

    func testExtractsArtworkTintFromAverageArtworkColor() {
        let artworkData = makeArtworkData(
            color: NSColor(calibratedRed: 0.15, green: 0.74, blue: 0.44, alpha: 1)
        )

        let palette = NowPlayingArtworkPaletteExtractor.extract(from: artworkData)
        let components = rgbaComponents(from: palette.equalizerBaseColor)

        XCTAssertGreaterThan(components.green, components.blue)
        XCTAssertGreaterThan(components.blue, components.red)
        XCTAssertNotEqual(palette, .fallback)
    }
}

private func makeArtworkData(
    color: NSColor,
    size: CGSize = CGSize(width: 20, height: 20)
) -> Data {
    let width = Int(size.width)
    let height = Int(size.height)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    color.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

private func rgbaComponents(from color: NSColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    let resolvedColor = color.usingColorSpace(.sRGB) ?? color
    return (
        resolvedColor.redComponent,
        resolvedColor.greenComponent,
        resolvedColor.blueComponent,
        resolvedColor.alphaComponent
    )
}
