//
//  ShazamViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI
import ShazamKit
import AVFoundation
import Accelerate
import Combine

enum ShazamState: Equatable {
    case listening
    case notFound
    case error(String)
}

struct ShazamResult: Equatable, Identifiable {
    var id: String { appleMusicURL?.absoluteString ?? (title + artist) }
    let title: String
    let artist: String
    let artworkURL: URL?
    let appleMusicURL: URL?
    let shazamURL: URL?
    let genres: [String]
}

@MainActor
final class ShazamViewModel: ObservableObject {
    @Published var state: ShazamState = .listening
    @Published var isListening: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var bandLevels: [Float] = [0.18, 0.18, 0.18, 0.18, 0.18]
    @Published var matchedResult: ShazamResult? = nil
    
    var notchViewModel: NotchViewModel? = nil
    
    private var managedSession: SHManagedSession?
    private var listeningTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var audioEngine: AVAudioEngine?
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            performStartListening()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted {
                        self.performStartListening()
                    } else {
                        self.state = .error("Microphone access denied.")
                    }
                }
            }
        case .denied, .restricted:
            state = .error("Microphone access denied.")
        @unknown default:
            performStartListening()
        }
    }
    
    private func performStartListening() {
        stopListening()
        
        let managedSession = SHManagedSession()
        self.managedSession = managedSession
        
        // Setup AVAudioEngine with Accelerate vDSP FFT for real-time 5-band spectrum analysis
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        try? inputNode.setVoiceProcessingEnabled(false)
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self = self, self.isListening else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount >= 256 else { return }
            
            // Calculate 5 frequency band levels via Accelerate vDSP FFT
            let log2n = UInt(log2(Double(frameCount)))
            let n = 1 << log2n
            
            var realPadded = [Float](repeating: 0, count: n)
            var imagPadded = [Float](repeating: 0, count: n)
            
            for i in 0..<n {
                realPadded[i] = channelData[i]
            }
            
            var splitComplex = DSPSplitComplex(realp: &realPadded, imagp: &imagPadded)
            guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
            
            vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
            vDSP_destroy_fftsetup(fftSetup)
            
            var magnitudes = [Float](repeating: 0, count: n / 2)
            vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(n / 2))
            
            let sampleRate = Float(buffer.format.sampleRate > 0 ? buffer.format.sampleRate : 44100.0)
            let binWidth = sampleRate / Float(n)
            
            // 5 Band boundaries (Hz): Bass (40-250), Low-Mid (250-800), Mid (800-2500), High-Mid (2500-6000), Treble (6000-16000)
            let bandRanges: [(Float, Float)] = [
                (40, 250),
                (250, 800),
                (800, 2500),
                (2500, 6000),
                (6000, 16000)
            ]
            
            var newBands = [Float](repeating: 0.18, count: 5)
            
            for i in 0..<5 {
                let lowBin = max(0, Int(bandRanges[i].0 / binWidth))
                let highBin = min(Int(bandRanges[i].1 / binWidth), n / 2 - 1)
                
                if lowBin < highBin {
                    var sum: Float = 0
                    for b in lowBin...highBin {
                        sum += magnitudes[b]
                    }
                    let avg = sqrt(sum / Float(highBin - lowBin + 1))
                    let db = 20 * log10(max(avg, 0.0001))
                    let norm = min(max((db + 50.0) / 45.0, 0.18), 1.0)
                    newBands[i] = norm
                }
            }
            
            DispatchQueue.main.async {
                for i in 0..<5 {
                    self.bandLevels[i] = self.bandLevels[i] * 0.35 + newBands[i] * 0.65
                }
                self.audioLevel = self.bandLevels.reduce(0, +) / 5.0
            }
        }
        
        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
        } catch {
            print("Visualizer audio engine start error: \(error.localizedDescription)")
        }
        
        isListening = true
        state = .listening
        matchedResult = nil
        
        // Listen to SHManagedSession results stream
        listeningTask?.cancel()
        listeningTask = Task { [weak self] in
            for await result in managedSession.results {
                guard let self = self, !Task.isCancelled, self.isListening else { break }
                
                switch result {
                case .match(let match):
                    if let mediaItem = match.mediaItems.first {
                        let result = ShazamResult(
                            title: mediaItem.title ?? "Unknown Title",
                            artist: mediaItem.artist ?? "Unknown Artist",
                            artworkURL: mediaItem.artworkURL,
                            appleMusicURL: mediaItem.appleMusicURL,
                            shazamURL: mediaItem.webURL,
                            genres: mediaItem.genres
                        )
                        self.stopListening()
                        self.matchedResult = result
                    }
                case .noMatch:
                    break
                case .error(let error, _):
                    let nsError = error as NSError
                    if nsError.domain == "com.apple.ShazamKit" && (nsError.code == 202 || nsError.code == 201) {
                        // Normal non-match during streaming interval
                        break
                    }
                    print("SHManagedSession result error: \(error.localizedDescription)")
                @unknown default:
                    break
                }
            }
        }
        
        // 20 seconds recognition timeout
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            guard let self = self, !Task.isCancelled, self.isListening else { return }
            self.stopListening()
            if self.matchedResult == nil {
                self.state = .notFound
            }
        }
    }
    
    func stopListening() {
        timeoutTask?.cancel()
        timeoutTask = nil
        listeningTask?.cancel()
        listeningTask = nil
        
        if let inputNode = audioEngine?.inputNode {
            inputNode.removeTap(onBus: 0)
        }
        audioEngine?.stop()
        audioEngine = nil
        
        managedSession?.cancel()
        managedSession = nil
        
        isListening = false
        audioLevel = 0.0
        bandLevels = [0.18, 0.18, 0.18, 0.18, 0.18]
    }
}
