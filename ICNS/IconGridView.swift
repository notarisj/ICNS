//
//  IconGridView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

struct IconGridView: View {
    let icons: [Icon]
    @Binding var selectedIconID: Icon.ID?
    @Binding var showInspector: Bool
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
    ]
    
    var body: some View {
        if icons.isEmpty {
            WelcomeView(showInspector: $showInspector)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons) { icon in
                        IconGridItem(icon: icon, isSelected: selectedIconID == icon.id)
                            .onTapGesture {
                                selectedIconID = icon.id
                            }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        WindowHelper.toggleInspectorWithResize($showInspector)
                    } label: {
                        Label("Inspector", systemImage: "slider.horizontal.3")
                    }
                    .help("Show or hide the inspector panel")
                }
            }
        }
    }

}

struct IconGridItem: View {
    let icon: Icon
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                
                if let imageURL = icon.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                             ProgressView()
                                .controlSize(.small)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 100)
            
            Text(icon.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(width: 100)
    }
}

#Preview {
    IconGridView(icons: [], selectedIconID: .constant(nil), showInspector: .constant(true))
}
