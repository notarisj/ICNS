//
//  SFSymbolPickerView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

struct SFSymbolPickerView: View {
    @Binding var selectedSymbol: String
    @State private var searchText = ""
    
    // Curated list of common SF Symbols suitable for categories
    private let symbols = [
        // Common categories
        "folder", "folder.fill", "tray", "tray.fill",
        "archivebox", "archivebox.fill", "shippingbox", "shippingbox.fill",
        
        // Work & productivity
        "briefcase", "briefcase.fill", "doc", "doc.fill",
        "book", "book.fill", "bookmark", "bookmark.fill",
        "calendar", "calendar.circle", "clock", "clock.fill",
        
        // Creative
        "paintbrush", "paintbrush.fill", "photo", "photo.fill",
        "camera", "camera.fill", "film", "film.fill",
        "music.note", "guitars", "theatermasks", "theatermasks.fill",
        
        // Communication
        "envelope", "envelope.fill", "message", "message.fill",
        "phone", "phone.fill", "video", "video.fill",
        
        // Technology
        "desktopcomputer", "laptopcomputer", "iphone", "ipad",
        "applewatch", "cpu", "memorychip", "internaldrive",
        
        // Education
        "graduationcap", "graduationcap.fill", "pencil", "pencil.circle",
        "book.closed", "books.vertical", "studentdesk", "backpack",
        
        // Shopping & finance
        "cart", "cart.fill", "bag", "bag.fill",
        "creditcard", "creditcard.fill", "dollarsign.circle", "banknote",
        
        // Health & fitness
        "heart", "heart.fill", "cross.case", "cross.case.fill",
        "figure.walk", "figure.run", "dumbbell", "dumbbell.fill",
        
        // Travel & places
        "airplane", "car", "car.fill", "bicycle",
        "house", "house.fill", "building", "building.2",
        "mappin", "mappin.circle", "globe", "globe.americas",
        
        // Nature
        "leaf", "leaf.fill", "tree", "cloud",
        "sun.max", "sun.max.fill", "moon", "moon.fill",
        "star", "star.fill", "sparkles", "flame",
        
        // Food & drink
        "cup.and.saucer", "cup.and.saucer.fill", "fork.knife", "birthday.cake",
        "wineglass", "mug", "takeoutbag.and.cup.and.straw", "carrot",
        
        // Symbols & shapes
        "square.grid.2x2", "circle.grid.3x3", "square.stack", "square.stack.fill",
        "tag", "tag.fill", "flag", "flag.fill",
        "bell", "bell.fill", "lightbulb", "lightbulb.fill",
        "gear", "gearshape", "wrench", "wrench.fill",
        "shield", "shield.fill", "lock", "lock.fill",
        "key", "key.fill", "checkmark.seal", "checkmark.seal.fill"
    ]
    
    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return symbols
        }
        return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search symbols", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            // Symbol grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedSymbol == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                                
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedSymbol == symbol ? .primary : .secondary)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .buttonStyle(.plain)
                        .help(symbol)
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 450)
    }
}

#Preview {
    SFSymbolPickerView(selectedSymbol: .constant("folder.fill"))
}
