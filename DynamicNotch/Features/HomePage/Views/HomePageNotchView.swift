//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

struct HomePageNotchView: View {
    var body: some View {
        VStack {
            Spacer()
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue)
                .frame(height: 100)
        }
        .padding(.horizontal, 30)
    }
}
