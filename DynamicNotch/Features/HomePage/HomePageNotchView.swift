//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: CaseIterable, Hashable {
    case camera
    case localTimer
    case calendar
}

struct HomePageNotchView: View {
    let notchViewModel: NotchViewModel
    let localTimerViewModel: LocalTimerViewModel
    let calendarViewModel: CalendarViewModel
    
    @State private var currentPage: HomePages?
    
    init(notchViewModel: NotchViewModel, localTimerViewModel: LocalTimerViewModel, calendarViewModel: CalendarViewModel, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.localTimerViewModel = localTimerViewModel
        self.calendarViewModel = calendarViewModel
        self._currentPage = State(initialValue: initialPage)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(HomePages.allCases, id: \.self) { page in
                        pageView(for: page)
                            .clipped()
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
            .onChange(of: currentPage) { oldPage, newPage in
                guard let newPage = newPage else { return }
                notchViewModel.send(
                    .showLiveActivity(
                        HomePageNotchContent(
                            notchViewModel: notchViewModel,
                            homePages: newPage,
                            localTimerViewModel: localTimerViewModel,
                            calendarViewModel: calendarViewModel
                        )
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, bottomPadding)
        .onDisappear {
            notchViewModel.send(
                .showLiveActivity(
                    HomePageNotchContent(
                        notchViewModel: notchViewModel,
                        homePages: .camera,
                        localTimerViewModel: localTimerViewModel,
                        calendarViewModel: calendarViewModel
                    )
                )
            )
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, localTimerViewModel: localTimerViewModel, calendarViewModel: calendarViewModel)
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .calendar:
            CalendarNotchView(calendarViewModel: calendarViewModel)
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch currentPage {
        case .camera:
            35
        case .localTimer:
            35
        case .calendar:
            35
        case .none:
            0
        }
    }
    
    private var bottomPadding: CGFloat {
        switch currentPage {
        case .camera:
            10
        case .localTimer:
            10
        case .calendar:
            10
        case .none:
            0
        }
    }
}
