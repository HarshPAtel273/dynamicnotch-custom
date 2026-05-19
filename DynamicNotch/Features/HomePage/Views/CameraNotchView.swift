//
//  CameraNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/19/26.
//

import SwiftUI
import AVFoundation

struct CameraNotchView: View {
    let notchViewModel: NotchViewModel
    
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var isHovering: Bool = false
    @State private var previewID = UUID()
    
    @AppStorage("isNotchLocked") private var isNotchLocked = false
    @AppStorage("isCameraMirrored") private var isCameraMirrored = false
    @AppStorage("isCameraLarge") private var isCameraLarge = false
    
    var body: some View {
        ZStack {
            switch cameraViewModel.cameraState {
            case .ready:
                cameraView
                
            case .unavailable:
                cameraUnavailableView
                
            case .unknown:
                progressView
            }
        }
        .padding(.horizontal, 3)
        .onAppear {
            previewID = UUID()
            cameraViewModel.startSession()
        }
        .onDisappear {
            isNotchLocked = false
            cameraViewModel.stopSession()
        }
    }
    
    @ViewBuilder
    private var cameraView: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottom) {
                CameraPreviewView(previewLayer: cameraViewModel.previewLayer)
                    .frame(height: isCameraLarge ? 205 : 165)
                    .scaleEffect(x: isCameraMirrored ? 1 : -1, y: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .id(previewID)
                    .transition(.blurAndFade.combined(with: .scale).animation(.spring(response: 0.6)))
                
                HStack {
                    if isHovering {
                        Button(action: {
                            withAnimation {
                                isNotchLocked.toggle()
                            }
                        }) {
                            ZStack {
                                Image(systemName: isNotchLocked ? "lock.fill" : "lock.open.fill")
                                    .foregroundStyle(isNotchLocked ? Color.accentColor : .white)
                                    .id(isNotchLocked)
                                    .transition(.scale.animation(.spring(response: 0.3)))
                            }
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(isNotchLocked ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial)))
                        }
                        
                        Button(action: {
                            withAnimation {
                                isCameraLarge.toggle()
                            }
                            notchViewModel.send(.showLiveActivity(HomePageNotchContent(notchViewModel: notchViewModel, homePages: .camera)))
                        }) {
                            ZStack {
                                Image(systemName: isCameraLarge ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .foregroundStyle(isCameraLarge ? Color.accentColor : .white)
                                    .id(isCameraLarge)
                                    .transition(.scale.animation(.spring(response: 0.3)))
                            }
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(isCameraLarge ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial)))
                        }
                        
                        Button(action: {
                            withAnimation {
                                isCameraMirrored.toggle()
                            }
                        }) {
                            ZStack {
                                Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                                    .foregroundStyle(isCameraMirrored ? Color.accentColor : .white)
                                    .id(isCameraMirrored)
                                    .transition(.scale.animation(.spring(response: 0.3)))
                            }
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(isCameraMirrored ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial)))
                        }
                    }
                }
                .font(.system(size: 14))
                .padding(.bottom, 10)
                .buttonStyle(.plain)
            }
            .onHover { isHovering = $0 }
            .animation(.spring(response: 0.4), value: isHovering)
        }
    }
    
    @ViewBuilder
    private var cameraUnavailableView: some View {
        VStack(spacing: 10) {
            Image(systemName: "video.slash")
                .font(.system(size: 46))
                .foregroundColor(.gray)
            
            Text("Camera is unavailable")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
    }
}

struct CameraPreviewView: NSViewRepresentable {
    var previewLayer: AVCaptureVideoPreviewLayer
    
    func makeNSView(context: Context) -> PreviewView {
        return PreviewView(previewLayer: previewLayer)
    }
    
    func updateNSView(_ nsView: PreviewView, context: Context) {
        
    }
}
