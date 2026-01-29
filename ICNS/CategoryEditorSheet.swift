//
//  CategoryEditorSheet.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

struct CategoryEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var category: Category?
    let onSave: (Category) -> Void
    
    @State private var name: String
    @State private var iconName: String
    @State private var color: CategoryColor
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
    
    init(category: Binding<Category?>, onSave: @escaping (Category) -> Void) {
        self._category = category
        self.onSave = onSave
        
        // Initialize state
        if let cat = category.wrappedValue {
            _name = State(initialValue: cat.name)
            _iconName = State(initialValue: cat.iconName)
            _color = State(initialValue: cat.color)
        } else {
            _name = State(initialValue: "")
            _iconName = State(initialValue: "folder.fill")
            _color = State(initialValue: .blue)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section with Preview
            VStack(spacing: 20) {
                // Circle Preview
                ZStack {
                    Circle()
                        .fill(color.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.top, 10)
                
                // Name Field
                TextField("Category Name", text: $name)
                    .textFieldStyle(.plain)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: 300)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Selection Area
            ScrollView {
                VStack(spacing: 24) {
                    // Colors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
                            ForEach(CategoryColor.allCases) { categoryColor in
                                Circle()
                                    .fill(categoryColor.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(.white)
                                            .opacity(color == categoryColor ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            color = categoryColor
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Icons
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Icon")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                            ForEach(filteredSymbols, id: \.self) { symbol in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(iconName == symbol ? Color.accentColor.opacity(0.15) : Color.clear)
                                    
                                    Image(systemName: symbol)
                                        .font(.system(size: 20))
                                        .foregroundStyle(iconName == symbol ? Color.accentColor : .secondary)
                                }
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    iconName = symbol
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 20)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(category == nil ? "Create" : "Done") {
                    saveCategory()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 500, height: 650)
    }
    
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let finalCategory: Category
        if var existing = category {
            existing.name = trimmedName
            existing.iconName = iconName
            existing.color = color
            finalCategory = existing
        } else {
            finalCategory = Category(
                name: trimmedName,
                iconName: iconName,
                color: color,
                order: 0
            )
        }
        
        onSave(finalCategory)
        dismiss()
    }
}

#Preview {
    CategoryEditorSheet(category: .constant(nil)) { _ in }
}
