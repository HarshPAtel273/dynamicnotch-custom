//
//  FileConverterViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import Foundation
import Combine
@preconcurrency import AVFoundation
import ImageIO
import UniformTypeIdentifiers
internal import AppKit

enum FileConverterMediaKind {
    case image
    case video
    case audio
    case archive
    case generic

    var defaultOutputFormat: FileConverterOutputFormat {
        switch self {
        case .image:
            return .png
        case .video:
            return .mp4
        case .audio:
            return .m4a
        case .archive:
            return .tar
        case .generic:
            return .zip
        }
    }
}

enum FileConverterOutputFormat: String, CaseIterable, Identifiable {
    case png
    case jpeg
    case heic
    case heif
    case heicSequence
    case webp
    case avif
    case tiff
    case gif
    case bmp
    case jpeg2000
    case ico
    case icns
    case pdf
    case psd
    case openEXR
    case dds
    case tga
    case astc
    case ktx
    case ktx2
    case pbm
    case pvr
    case atx
    case mp4
    case mov
    case m4v
    case threeGP
    case threeG2
    case audio3GPP
    case audio3GPP2
    case aac
    case ac3
    case aifc
    case aiff
    case amr
    case m4a
    case m4b
    case caf
    case eac3
    case flac
    case loas
    case mp1
    case mp2
    case mp3
    case audioMP4
    case au
    case ogg
    case sd2
    case wav
    case bw64
    case rf64
    case w64
    case zip
    case tar
    case tarGzip
    case tarBzip2
    case gzip
    case bzip2
    case unixCompress

    var id: String { rawValue }

    var title: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        case .heic: return "HEIC"
        case .heif: return "HEIF"
        case .heicSequence: return "HEICS"
        case .webp: return "WEBP"
        case .avif: return "AVIF"
        case .tiff: return "TIFF"
        case .gif: return "GIF"
        case .bmp: return "BMP"
        case .jpeg2000: return "JP2"
        case .ico: return "ICO"
        case .icns: return "ICNS"
        case .pdf: return "PDF"
        case .psd: return "PSD"
        case .openEXR: return "EXR"
        case .dds: return "DDS"
        case .tga: return "TGA"
        case .astc: return "ASTC"
        case .ktx: return "KTX"
        case .ktx2: return "KTX2"
        case .pbm: return "PBM"
        case .pvr: return "PVR"
        case .atx: return "ATX"
        case .mp4: return "MP4"
        case .mov: return "MOV"
        case .m4v: return "M4V"
        case .threeGP: return "3GP"
        case .threeG2: return "3G2"
        case .audio3GPP: return "3GPP"
        case .audio3GPP2: return "3GPP2"
        case .aac: return "AAC"
        case .ac3: return "AC3"
        case .aifc: return "AIFC"
        case .aiff: return "AIFF"
        case .amr: return "AMR"
        case .m4a: return "M4A"
        case .m4b: return "M4B"
        case .caf: return "CAF"
        case .eac3: return "EC3"
        case .flac: return "FLAC"
        case .loas: return "LOAS"
        case .mp1: return "MP1"
        case .mp2: return "MP2"
        case .mp3: return "MP3"
        case .audioMP4: return "MP4 Audio"
        case .au: return "AU"
        case .ogg: return "OGG"
        case .sd2: return "SD2"
        case .wav: return "WAV"
        case .bw64: return "BW64"
        case .rf64: return "RF64"
        case .w64: return "W64"
        case .zip: return "ZIP"
        case .tar: return "TAR"
        case .tarGzip: return "TAR.GZ"
        case .tarBzip2: return "TAR.BZ2"
        case .gzip: return "GZ"
        case .bzip2: return "BZ2"
        case .unixCompress: return "Z"
        }
    }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .heic: return "heic"
        case .heif: return "heif"
        case .heicSequence: return "heics"
        case .webp: return "webp"
        case .avif: return "avif"
        case .tiff: return "tiff"
        case .gif: return "gif"
        case .bmp: return "bmp"
        case .jpeg2000: return "jp2"
        case .ico: return "ico"
        case .icns: return "icns"
        case .pdf: return "pdf"
        case .psd: return "psd"
        case .openEXR: return "exr"
        case .dds: return "dds"
        case .tga: return "tga"
        case .astc: return "astc"
        case .ktx: return "ktx"
        case .ktx2: return "ktx2"
        case .pbm: return "pbm"
        case .pvr: return "pvr"
        case .atx: return "atx"
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .m4v: return "m4v"
        case .threeGP, .audio3GPP: return "3gp"
        case .threeG2, .audio3GPP2: return "3g2"
        case .aac: return "aac"
        case .ac3: return "ac3"
        case .aifc: return "aifc"
        case .aiff: return "aiff"
        case .amr: return "amr"
        case .m4a: return "m4a"
        case .m4b: return "m4b"
        case .caf: return "caf"
        case .eac3: return "ec3"
        case .flac: return "flac"
        case .loas: return "loas"
        case .mp1: return "mp1"
        case .mp2: return "mp2"
        case .mp3: return "mp3"
        case .audioMP4: return "mp4"
        case .au: return "au"
        case .ogg: return "ogg"
        case .sd2: return "sd2"
        case .wav, .bw64, .rf64: return "wav"
        case .w64: return "w64"
        case .zip: return "zip"
        case .tar: return "tar"
        case .tarGzip: return "tar.gz"
        case .tarBzip2: return "tar.bz2"
        case .gzip: return "gz"
        case .bzip2: return "bz2"
        case .unixCompress: return "Z"
        }
    }

    var filenameExtensions: [String] {
        switch self {
        case .jpeg:
            return ["jpg", "jpeg", "jpe", "jfif"]
        case .tiff:
            return ["tif", "tiff"]
        case .jpeg2000:
            return ["jp2", "j2k", "jpf", "jpx", "jpeg2000"]
        case .threeGP, .audio3GPP:
            return ["3gp", "3gpp"]
        case .threeG2, .audio3GPP2:
            return ["3g2", "3gp2", "3gpp2"]
        case .aiff:
            return ["aiff", "aif"]
        case .amr:
            return ["amr", "awb"]
        case .m4a:
            return ["m4a", "m4r"]
        case .eac3:
            return ["ec3", "eac3"]
        case .audioMP4:
            return ["mp4", "mpg4"]
        case .au:
            return ["au", "snd"]
        case .ogg:
            return ["ogg", "oga", "opus"]
        case .wav, .bw64, .rf64:
            return ["wav"]
        case .tarGzip:
            return ["tar.gz", "tgz"]
        case .tarBzip2:
            return ["tar.bz2", "tbz", "tbz2"]
        case .unixCompress:
            return ["z"]
        default:
            return [fileExtension]
        }
    }

    var mediaKind: FileConverterMediaKind {
        switch self {
        case .png, .jpeg, .heic, .heif, .heicSequence, .webp, .avif, .tiff, .gif,
             .bmp, .jpeg2000, .ico, .icns, .pdf, .psd, .openEXR, .dds, .tga,
             .astc, .ktx, .ktx2, .pbm, .pvr, .atx:
            return .image
        case .mp4, .mov, .m4v, .threeGP, .threeG2:
            return .video
        case .audio3GPP, .audio3GPP2, .aac, .ac3, .aifc, .aiff, .amr, .m4a,
             .m4b, .caf, .eac3, .flac, .loas, .mp1, .mp2, .mp3, .audioMP4,
             .au, .ogg, .sd2, .wav, .bw64, .rf64, .w64:
            return .audio
        case .zip, .tar, .tarGzip, .tarBzip2, .gzip, .bzip2, .unixCompress:
            return .archive
        }
    }

    var imageTypeIdentifier: String? {
        switch self {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        case .heic: return "public.heic"
        case .heif: return "public.heif"
        case .heicSequence: return "public.heics"
        case .webp: return "org.webmproject.webp"
        case .avif: return "public.avif"
        case .tiff: return "public.tiff"
        case .gif: return "com.compuserve.gif"
        case .bmp: return "com.microsoft.bmp"
        case .jpeg2000: return "public.jpeg-2000"
        case .ico: return "com.microsoft.ico"
        case .icns: return "com.apple.icns"
        case .pdf: return "com.adobe.pdf"
        case .psd: return "com.adobe.photoshop-image"
        case .openEXR: return "com.ilm.openexr-image"
        case .dds: return "com.microsoft.dds"
        case .tga: return "com.truevision.tga-image"
        case .astc: return "org.khronos.astc"
        case .ktx: return "org.khronos.ktx"
        case .ktx2: return "org.khronos.ktx2"
        case .pbm: return "public.pbm"
        case .pvr: return "public.pvr"
        case .atx: return "com.apple.atx"
        default: return nil
        }
    }

    var avFileType: AVFileType? {
        switch self {
        case .mp4: return .mp4
        case .mov: return .mov
        case .m4v: return .m4v
        case .threeGP: return .mobile3GPP
        case .threeG2: return .mobile3GPP2
        default: return nil
        }
    }

    var afconvertFileFormat: String? {
        switch self {
        case .audio3GPP: return "3gpp"
        case .audio3GPP2: return "3gp2"
        case .aac: return "adts"
        case .ac3: return "ac-3"
        case .aifc: return "AIFC"
        case .aiff: return "AIFF"
        case .amr: return "amrf"
        case .m4a: return "m4af"
        case .m4b: return "m4bf"
        case .caf: return "caff"
        case .eac3: return "ec-3"
        case .flac: return "flac"
        case .loas: return "loas"
        case .mp1: return "MPG1"
        case .mp2: return "MPG2"
        case .mp3: return "MPG3"
        case .audioMP4: return "mp4f"
        case .au: return "NeXT"
        case .ogg: return "Oggf"
        case .sd2: return "Sd2f"
        case .wav: return "WAVE"
        case .bw64: return "BW64"
        case .rf64: return "RF64"
        case .w64: return "W64f"
        default: return nil
        }
    }

    var afconvertDataFormat: String? {
        switch self {
        case .audio3GPP, .audio3GPP2, .aac, .m4a, .m4b, .loas, .audioMP4:
            return "aac "
        case .ac3:
            return "ac-3"
        case .eac3:
            return "ec-3"
        case .aifc, .aiff, .au, .sd2:
            return "BEI16"
        case .amr:
            return "samr"
        case .caf, .wav, .bw64, .rf64, .w64:
            return "LEI16"
        case .flac:
            return "flac"
        case .mp1:
            return ".mp1"
        case .mp2:
            return ".mp2"
        case .mp3:
            return ".mp3"
        case .ogg:
            return "opus"
        default:
            return nil
        }
    }

    static func formats(for kind: FileConverterMediaKind, isDirectory: Bool = false) -> [FileConverterOutputFormat] {
        switch kind {
        case .image:
            return imageFormats + archiveFormats(isDirectory: isDirectory)
        case .video:
            return videoFormats + archiveFormats(isDirectory: isDirectory)
        case .audio:
            return audioFormats + archiveFormats(isDirectory: isDirectory)
        case .archive, .generic:
            return archiveFormats(isDirectory: isDirectory)
        }
    }

    private static var imageFormats: [FileConverterOutputFormat] {
        allCases.filter { $0.mediaKind == .image && $0.isAvailableImageDestination }
    }

    private static var videoFormats: [FileConverterOutputFormat] {
        allCases.filter { $0.mediaKind == .video }
    }

    private static var audioFormats: [FileConverterOutputFormat] {
        allCases.filter { $0.mediaKind == .audio && $0.afconvertFileFormat != nil }
    }

    private static func archiveFormats(isDirectory: Bool) -> [FileConverterOutputFormat] {
        let formats: [FileConverterOutputFormat] = [.zip, .tar, .tarGzip, .tarBzip2]
        guard !isDirectory else { return formats }
        return formats + [.gzip, .bzip2, .unixCompress]
    }

    private var isAvailableImageDestination: Bool {
        guard let imageTypeIdentifier else { return false }
        return Self.availableImageDestinationTypeIdentifiers.contains(imageTypeIdentifier)
    }

    private static let availableImageDestinationTypeIdentifiers: Set<String> = {
        let identifiers = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        return Set(identifiers)
    }()
}

struct FileConverterItem: Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let fileExtension: String
    let mediaKind: FileConverterMediaKind
    let isDirectory: Bool

    init(url: URL, mediaKind: FileConverterMediaKind, isDirectory: Bool) {
        let standardizedURL = url.standardizedFileURL
        self.url = standardizedURL
        self.displayName = standardizedURL.lastPathComponent.isEmpty ?
        standardizedURL.deletingLastPathComponent().lastPathComponent :
        standardizedURL.lastPathComponent
        self.fileExtension = standardizedURL.pathExtension.uppercased()
        self.mediaKind = mediaKind
        self.isDirectory = isDirectory
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

enum FileConverterStatus: Equatable {
    case idle
    case converting
    case converted(URL)
    case failed(String)
}

private enum FileConverterProcessRunner {
    static func run(
        executablePath: String,
        arguments: [String],
        standardOutputURL: URL? = nil
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let outputPipe = Pipe()
            process.standardError = outputPipe

            var outputHandle: FileHandle?
            if let standardOutputURL {
                FileManager.default.createFile(atPath: standardOutputURL.path, contents: nil)
                outputHandle = try FileHandle(forWritingTo: standardOutputURL)
                process.standardOutput = outputHandle
            } else {
                process.standardOutput = outputPipe
            }

            try process.run()
            process.waitUntilExit()
            try outputHandle?.close()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let outputText = String(data: outputData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard process.terminationStatus == 0 else {
                throw NSError(
                    domain: "DynamicNotch.FileConverter",
                    code: Int(process.terminationStatus),
                    userInfo: [
                        NSLocalizedDescriptionKey: outputText?.isEmpty == false ?
                        outputText! :
                            "The native converter could not finish this file."
                    ]
                )
            }
        }.value
    }
}

@MainActor
final class FileConverterViewModel: ObservableObject {
    @Published private(set) var item: FileConverterItem?
    @Published var selectedFormat: FileConverterOutputFormat = .png
    @Published private(set) var status: FileConverterStatus = .idle

    private var conversionTask: Task<Void, Never>?

    private static let imageInputExtensions: Set<String> = [
        "png", "jpg", "jpeg", "jpe", "jfif", "tif", "tiff", "gif", "bmp", "dib",
        "heic", "heif", "heics", "webp", "avif", "jp2", "j2k", "jpf", "jpx", "jpeg2000",
        "ico", "icns", "tga", "psd", "exr", "dds", "astc", "ktx", "ktx2", "pbm", "pvr",
        "pict", "pct", "sgi", "dng", "raw"
    ]

    private static let videoInputExtensions: Set<String> = [
        "mp4", "m4v", "mov", "qt", "3gp", "3gpp", "3g2", "3gp2", "3gpp2", "mpg",
        "mpeg", "mpe", "m2v", "ts", "mts", "m2ts", "avi", "mkv", "webm", "wmv", "flv"
    ]

    private static let audioInputExtensions: Set<String> = [
        "3gp", "3gpp", "3g2", "3gp2", "aac", "adts", "ac3", "aif", "aiff", "aifc",
        "amr", "awb", "m4a", "m4r", "m4b", "caf", "caff", "ec3", "eac3", "flac",
        "loas", "latm", "xhe", "mp1", "mp2", "mp3", "mpeg", "mpa", "m1a", "m2a",
        "mp4", "mpg4", "snd", "au", "ogg", "oga", "opus", "sd2", "wav", "wave", "w64", "wma"
    ]

    private static let archiveInputExtensions: Set<String> = [
        "zip", "tar", "tgz", "gz", "bz2", "tbz", "tbz2", "cpio", "pax", "xar", "xip", "pkg", "dmg", "z"
    ]

    var onItemChange: (@MainActor (FileConverterItem?) -> Void)? {
        didSet {
            onItemChange?(item)
        }
    }

    var hasItem: Bool {
        item != nil
    }

    var isConverting: Bool {
        status == .converting
    }

    var isConverted: Bool {
        if case .converted = status {
            return true
        }

        return false
    }

    var availableFormats: [FileConverterOutputFormat] {
        guard let item else {
            return FileConverterOutputFormat.formats(for: .image)
        }

        return FileConverterOutputFormat.formats(
            for: item.mediaKind,
            isDirectory: item.isDirectory
        )
    }

    func setFile(_ url: URL) throws {
        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Choose a file or folder to convert."]
            )
        }

        let converterItem = FileConverterItem(
            url: standardizedURL,
            mediaKind: mediaKind(for: standardizedURL, isDirectory: isDirectory.boolValue),
            isDirectory: isDirectory.boolValue
        )
        item = converterItem
        selectedFormat = defaultFormat(for: converterItem)
        status = .idle
        onItemChange?(converterItem)
    }

    func convert() {
        guard let item, status != .converting else { return }

        conversionTask?.cancel()
        status = .converting

        let outputFormat = selectedFormat

        if outputFormat.mediaKind == .archive {
            conversionTask = Task { [weak self] in
                await self?.runAsyncConversion {
                    try await self?.convertArchive(at: item.url, isDirectory: item.isDirectory, to: outputFormat)
                }
            }
            return
        }

        switch (item.mediaKind, outputFormat.mediaKind) {
        case (.image, .image):
            do {
                let outputURL = try convertImage(at: item.url, to: outputFormat)
                status = .converted(outputURL)
            } catch {
                status = .failed(error.localizedDescription)
            }

        case (.video, .video):
            conversionTask = Task { [weak self] in
                await self?.runAsyncConversion {
                    try await self?.convertVideo(at: item.url, to: outputFormat)
                }
            }

        case (.audio, .audio):
            conversionTask = Task { [weak self] in
                await self?.runAsyncConversion {
                    try await self?.convertAudio(at: item.url, to: outputFormat)
                }
            }

        default:
            status = .failed("\(outputFormat.title) is not available for this file.")
        }
    }

    func revealConvertedFile() {
        guard case .converted(let outputURL) = status else { return }

        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    func clear() {
        conversionTask?.cancel()
        conversionTask = nil
        item = nil
        status = .idle
        onItemChange?(nil)
    }

    private func runAsyncConversion(_ conversion: () async throws -> URL?) async {
        do {
            guard let outputURL = try await conversion() else { return }
            guard !Task.isCancelled else { return }
            status = .converted(outputURL)
        } catch {
            guard !Task.isCancelled else { return }
            status = .failed(error.localizedDescription)
        }
    }

    private func defaultFormat(for item: FileConverterItem) -> FileConverterOutputFormat {
        FileConverterOutputFormat.formats(for: item.mediaKind, isDirectory: item.isDirectory).first {
            $0.filenameExtensions.contains(item.fileExtension.lowercased()) == false
        } ?? item.mediaKind.defaultOutputFormat
    }

    private func convertImage(at sourceURL: URL, to format: FileConverterOutputFormat) throws -> URL {
        guard format.mediaKind == .image,
              let imageTypeIdentifier = format.imageTypeIdentifier else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Choose an image output format."]
            )
        }

        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Could not read this image."]
            )
        }

        let outputURL = uniqueOutputURL(for: sourceURL, format: format)
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            imageTypeIdentifier as CFString,
            1,
            nil
        ) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Could not create this image format."]
            )
        }

        let properties: CFDictionary?
        if format == .jpeg {
            properties = [kCGImageDestinationLossyCompressionQuality as String: 0.92] as CFDictionary
        } else {
            properties = nil
        }

        CGImageDestinationAddImage(destination, image, properties)

        guard CGImageDestinationFinalize(destination) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Could not encode this image."]
            )
        }

        return outputURL
    }

    private func convertVideo(at sourceURL: URL, to format: FileConverterOutputFormat) async throws -> URL {
        guard let outputFileType = format.avFileType else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 7,
                userInfo: [NSLocalizedDescriptionKey: "Choose a video output format."]
            )
        }

        let asset = AVURLAsset(url: sourceURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) ??
                AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 8,
                userInfo: [NSLocalizedDescriptionKey: "This media file cannot be exported by macOS."]
            )
        }

        guard exportSession.supportedFileTypes.contains(outputFileType) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 9,
                userInfo: [NSLocalizedDescriptionKey: "\(format.title) is not available for this file."]
            )
        }

        let outputURL = uniqueOutputURL(for: sourceURL, format: format)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType
        exportSession.shouldOptimizeForNetworkUse = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: ())

                case .failed:
                    continuation.resume(
                        throwing: exportSession.error ??
                        NSError(
                            domain: "DynamicNotch.FileConverter",
                            code: 10,
                            userInfo: [NSLocalizedDescriptionKey: "Could not export this media file."]
                        )
                    )

                case .cancelled:
                    continuation.resume(throwing: CancellationError())

                default:
                    continuation.resume(
                        throwing: NSError(
                            domain: "DynamicNotch.FileConverter",
                            code: 11,
                            userInfo: [NSLocalizedDescriptionKey: "Media export finished in an unknown state."]
                        )
                    )
                }
            }
        }

        return outputURL
    }

    private func convertAudio(at sourceURL: URL, to format: FileConverterOutputFormat) async throws -> URL {
        guard let fileFormat = format.afconvertFileFormat else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 12,
                userInfo: [NSLocalizedDescriptionKey: "Choose an audio output format."]
            )
        }

        let outputURL = uniqueOutputURL(for: sourceURL, format: format)
        var arguments = ["-f", fileFormat]
        if let dataFormat = format.afconvertDataFormat {
            arguments += ["-d", dataFormat]
        }
        arguments += [sourceURL.path, outputURL.path]

        try await FileConverterProcessRunner.run(
            executablePath: "/usr/bin/afconvert",
            arguments: arguments
        )
        return outputURL
    }

    private func convertArchive(
        at sourceURL: URL,
        isDirectory: Bool,
        to format: FileConverterOutputFormat
    ) async throws -> URL {
        let outputURL = uniqueOutputURL(for: sourceURL, format: format)
        let parentPath = sourceURL.deletingLastPathComponent().path
        let itemName = sourceURL.lastPathComponent

        switch format {
        case .zip:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/ditto",
                arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent", sourceURL.path, outputURL.path]
            )

        case .tar:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/tar",
                arguments: ["-cf", outputURL.path, "-C", parentPath, "--", itemName]
            )

        case .tarGzip:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/tar",
                arguments: ["-czf", outputURL.path, "-C", parentPath, "--", itemName]
            )

        case .tarBzip2:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/tar",
                arguments: ["-cjf", outputURL.path, "-C", parentPath, "--", itemName]
            )

        case .gzip:
            try validateSingleFileArchiveSource(isDirectory: isDirectory, format: format)
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/gzip",
                arguments: ["-c", sourceURL.path],
                standardOutputURL: outputURL
            )

        case .bzip2:
            try validateSingleFileArchiveSource(isDirectory: isDirectory, format: format)
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/bzip2",
                arguments: ["-c", sourceURL.path],
                standardOutputURL: outputURL
            )

        case .unixCompress:
            try validateSingleFileArchiveSource(isDirectory: isDirectory, format: format)
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/compress",
                arguments: ["-c", sourceURL.path],
                standardOutputURL: outputURL
            )

        default:
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 13,
                userInfo: [NSLocalizedDescriptionKey: "Choose an archive output format."]
            )
        }

        return outputURL
    }

    private func validateSingleFileArchiveSource(
        isDirectory: Bool,
        format: FileConverterOutputFormat
    ) throws {
        guard !isDirectory else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 14,
                userInfo: [NSLocalizedDescriptionKey: "\(format.title) can archive single files only. Use TAR or ZIP for folders."]
            )
        }
    }

    private func mediaKind(for url: URL, isDirectory: Bool) -> FileConverterMediaKind {
        guard !isDirectory else { return .generic }

        let pathExtension = url.pathExtension.lowercased()
        let contentType = UTType(filenameExtension: pathExtension)

        if Self.archiveInputExtensions.contains(pathExtension) {
            return .archive
        }

        if contentType?.conforms(to: .image) == true ||
            Self.imageInputExtensions.contains(pathExtension) ||
            NSImage(contentsOf: url) != nil {
            return .image
        }

        if contentType?.conforms(to: .movie) == true ||
            contentType?.conforms(to: .video) == true ||
            Self.videoInputExtensions.contains(pathExtension) {
            return .video
        }

        if contentType?.conforms(to: .audio) == true ||
            Self.audioInputExtensions.contains(pathExtension) {
            return .audio
        }

        return .generic
    }

    private func uniqueOutputURL(for sourceURL: URL, format: FileConverterOutputFormat) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let preferredName = "\(baseName)-converted"
        var candidate = directory
            .appendingPathComponent(preferredName)
            .appendingPathExtension(format.fileExtension)
        var suffix = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(preferredName)-\(suffix)")
                .appendingPathExtension(format.fileExtension)
            suffix += 1
        }

        return candidate
    }
}
