//
//  HomePageSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct HomePageSettingsView: View {
    @ObservedObject var settings: HomePageSettingsStore
    @State private var draggedPage: HomePages?
    
    var body: some View {
        SettingsPageScrollView {
            homePageActivity
            pagesConfig
        }
    }
    
    private var homePageActivity: some View {
        SettingsCard(title: "Home Page activity") {
            SettingsToggleRow(
                title: "Home Page live activity",
                description: "Show the Home Page in the notch.",
                systemImage: "house.fill",
                color: .black,
                isOn: $settings.isHomePageLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.homePage"
            )
        }
    }

    private var pagesConfig: some View {
        SettingsCard(title: LocalizedStringKey("Pages")) {
            VStack(spacing: 10) {
                ForEach(settings.homePageOrder, id: \.self) { page in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 14))
                            .frame(width: 16)
                        
                        HStack(alignment: .center, spacing: 12) {
                            SettingsIconBadge(
                                systemImage: page.icon,
                                tint: page.tint,
                                size: 30,
                                iconSize: 14,
                                cornerRadius: 9
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(page.title)
                                Text(page.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { !settings.homePageDisabled.contains(page) },
                            set: { isEnabled in
                                if isEnabled {
                                    settings.homePageDisabled.remove(page)
                                } else {
                                    settings.homePageDisabled.insert(page)
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .contentShape(Rectangle())
                    .opacity(draggedPage == page ? 0.01 : 1.0)
                    .onDrag {
                        self.draggedPage = page
                        return NSItemProvider(object: page.rawValue as NSString)
                    }
                    .onDrop(of: [.plainText], delegate: HomePageDragDelegate(item: page, items: $settings.homePageOrder, draggedItem: $draggedPage))
                    
                    Divider().opacity(0.6)
                }
            }
            Text(LocalizedStringKey("Drag to reorder pages. Disabled pages will be hidden."))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct HomePageDragDelegate: DropDelegate {
    let item: HomePages
    @Binding var items: [HomePages]
    @Binding var draggedItem: HomePages?

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem, draggedItem != item else { return }
        
        let from = items.firstIndex(of: draggedItem)
        let to = items.firstIndex(of: item)
        
        if let from = from, let to = to {
            withAnimation(.default) {
                items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
