//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: CaseIterable, Hashable {
    case camera
    case notes
}

struct HomePageNotchView: View {
    let notchViewModel: NotchViewModel
    @State private var currentPage: HomePages?
    
    init(notchViewModel: NotchViewModel, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self._currentPage = State(initialValue: initialPage)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(HomePages.allCases, id: \.self) { page in
                        pageView(for: page)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPage)
            .onChange(of: currentPage) { oldPage, newPage in
                guard let newPage = newPage else { return }
                notchViewModel.send(.showLiveActivity(HomePageNotchContent(notchViewModel: notchViewModel, homePages: newPage)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, 45)
        .padding(.bottom, 13)
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel)
        case .notes:
            Text("notes")
        }
    }
}
