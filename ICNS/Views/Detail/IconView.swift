//
//  IconView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 7/5/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct IconView: View {
    @Binding var icon: Icon
    @Binding var icons: [Icon]

    @Binding var showInspector: Bool
    @Binding var showAddIconSheet: Bool
    @Binding var showDeleteConfirmation: Bool
    @Binding var iconsGenerated: Bool
    @Binding var showClearImageConfirmation: Bool
    
    @EnvironmentObject var profileStore: ProfileStore
    @AppStorage("showImageBorder") private var showImageBorder = true
    
    @State private var currentImage: NSImage? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Main icon display or drop target
            IconPreviewArea(
                nsImage: currentImage,
                showImageBorder: showImageBorder,
                onImageDropped: { data in
                    self.icon.image = data
                    self.icon.outputDirectory = nil // Reset output directory on new image
                    self.iconsGenerated = false
                },
                onRequestImageSelection: selectImage
            )
            .id(icon.id) // Force reset on icon change
        }
        .onAppear {
            updateCurrentImage()
        }
        .onChange(of: icon.id) {
            updateCurrentImage()
        }
        .onChange(of: icon.imageID) {
            updateCurrentImage()
        }
        .onChange(of: icon.name) {
            iconsGenerated = false
        }

        .alert("Clear Image", isPresented: $showClearImageConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                performClearImage()
            }
        } message: {
            Text("Are you sure you want to clear this image and output directory? This action cannot be undone.")
        }
    }
    
    // MARK: - Functions
    
    func selectImage() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType.jpeg, UTType.png, UTType.gif, UTType.tiff, UTType.bmp]
        openPanel.begin { (result) in
            if result == .OK {
                if let url = openPanel.url, let nsImage = NSImage(contentsOf: url) {
                    self.icon.image = nsImage.tiffRepresentation
                }
            }
        }
    }
    
    func performClearImage() {
        self.icon.image = nil
        self.icon.outputDirectory = ""
        iconsGenerated = false
    }
    
    private func updateCurrentImage() {
        if let id = icon.imageID {
            // Load async to avoid blocking main thread with file IO
            Task.detached(priority: .userInitiated) {
                if let data = ImageStorageService.shared.loadImage(id: id),
                   let nsImage = NSImage(data: data) {
                    await MainActor.run {
                        // Verify the icon hasn't changed while we were loading
                        if self.icon.imageID == id {
                            self.currentImage = nsImage
                        }
                    }
                } else {
                    await MainActor.run {
                         if self.icon.imageID == id {
                            self.currentImage = nil
                         }
                    }
                }
            }
        } else if let data = icon.legacyImageData {
            // Legacy data is in memory, safe to load
            self.currentImage = NSImage(data: data)
        } else {
            self.currentImage = nil
        }
    }
}

// MARK: - Icon Preview Area

private struct IconPreviewArea: View {
    let nsImage: NSImage?
    let showImageBorder: Bool
    let onImageDropped: (Data) -> Void
    let onRequestImageSelection: () -> Void
    
    @State private var isDropTargeted = false
    
    // Zoom & Pan State
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background to capture clicks/drags anywhere
                Color.clear
                    .contentShape(Rectangle())
                
                if let img = nsImage {
                    ZStack {
                        Color.clear // Tap area for dragging
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let tentativeOffset = CGSize(
                                            width: lastDragOffset.width + value.translation.width,
                                            height: lastDragOffset.height + value.translation.height
                                        )
                                        
                                        // Calculate constraints
                                        let baseSize = min(geometry.size.width, geometry.size.height) * 0.8
                                        let currentSize = baseSize * zoomScale
                                        let maxOffsetX = abs(geometry.size.width - currentSize) / 2
                                        let maxOffsetY = abs(geometry.size.height - currentSize) / 2
                                        
                                        dragOffset = CGSize(
                                            width: min(max(tentativeOffset.width, -maxOffsetX), maxOffsetX),
                                            height: min(max(tentativeOffset.height, -maxOffsetY), maxOffsetY)
                                        )
                                    }
                                    .onEnded { value in
                                        lastDragOffset = dragOffset
                                    }
                            )
                            // Add MagnificationGesture for trackpad pinch
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        if lastZoomScale != 0 {
                                            let delta = value / lastZoomScale
                                            lastZoomScale = value
                                            let newScale = zoomScale * delta
                                            zoomScale = min(max(newScale, 0.1), 5.0)
                                            
                                            // Re-clamp offset if we zoom out
                                            let baseSize = min(geometry.size.width, geometry.size.height) * 0.8
                                            let currentSize = baseSize * zoomScale
                                            let maxOffsetX = abs(geometry.size.width - currentSize) / 2
                                            let maxOffsetY = abs(geometry.size.height - currentSize) / 2
                                            
                                            dragOffset = CGSize(
                                                width: min(max(dragOffset.width, -maxOffsetX), maxOffsetX),
                                                height: min(max(dragOffset.height, -maxOffsetY), maxOffsetY)
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastZoomScale = 1.0
                                    }
                            )
                        
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: min(geometry.size.width, geometry.size.height) * 0.8,
                                   height: min(geometry.size.width, geometry.size.height) * 0.8) // Initial size relative to container
                            .scaleEffect(zoomScale)
                            .offset(dragOffset)
                            .overlay(
                                Group {
                                    if showImageBorder {
                                        Rectangle()
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1 / zoomScale)
                                            .scaleEffect(zoomScale)
                                            .offset(dragOffset)
                                    }
                                }
                            )
                            .allowsHitTesting(false) // Pass touches to the container for dragging
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .onChange(of: nsImage) {
                        zoomScale = 1.0
                        dragOffset = .zero
                        lastDragOffset = .zero
                        lastZoomScale = 1.0
                    }
                    .overlay(alignment: .bottom) {
                        if zoomScale != 1.0 || dragOffset != .zero {
                            HStack(spacing: 8) {
                                Text("\(Int(zoomScale * 100))%")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                
                                Divider()
                                    .frame(height: 12)
                                
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        zoomScale = 1.0
                                        dragOffset = .zero
                                        lastDragOffset = .zero
                                        lastZoomScale = 1.0
                                    }
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .help("Reset View")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.regularMaterial)
                            .cornerRadius(16)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    
                } else {
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(isDropTargeted ? 0.2 : 0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 36))
                                .foregroundStyle(.tint)
                                .scaleEffect(isDropTargeted ? 1.1 : 1.0)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDropTargeted)
                        
                        VStack(spacing: 6) {
                            Text(isDropTargeted ? "Drop Image Here" : "Drop Master Image")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("Drag your 1024x1024 artwork here\nor click to browse files")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 250)
                        }
                    }
                    .frame(maxWidth: 360, maxHeight: 360)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.accentColor.opacity(isDropTargeted ? 0.1 : 0.02))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(style: StrokeStyle(lineWidth: isDropTargeted ? 3 : 2, dash: isDropTargeted ? [] : [10, 6]))
                                .foregroundStyle(isDropTargeted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary.opacity(0.5)))
                        }
                    )
                    .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                    
                    .contentShape(Rectangle())
                    .onDrop(of: [UTType.image], isTargeted: $isDropTargeted) { providers -> Bool in
                        providers.first?.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier,
                                                                completionHandler: { (data, error) in
                            if let data = data {
                                DispatchQueue.main.async {
                                    onImageDropped(data)
                                }
                            }
                        })
                        return true
                    }
                    .onTapGesture {
                        onRequestImageSelection()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
