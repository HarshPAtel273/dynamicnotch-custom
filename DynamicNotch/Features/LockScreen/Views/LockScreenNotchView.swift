//
//  LockScreenNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var lockScreenManager: LockScreenManager
    let style: LockScreenStyle

    var body: some View {
        HStack {
            Image(systemName: lockScreenManager.isShowingLockPresentation ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()

            if style == .enlarged {
                Text(verbatim: lockScreenManager.isShowingLockPresentation ? "Locked" : "Unlocked")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
