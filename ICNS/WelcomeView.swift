//
//  WelcomeView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 29/1/26.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showInspector: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "app.dashed")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
            }
            
            VStack(spacing: 8) {
                Text("Welcome to ICNS")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create a new icon set to start generating\nicons for macOS and iOS.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.square")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Create Set")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Click + in the toolbar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 150, alignment: .leading)
                
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drag & Drop")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Add your master image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 150, alignment: .leading)
                
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Generate icons & ICNS")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 150, alignment: .leading)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        .background(Color(nsColor: .textBackgroundColor))
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
