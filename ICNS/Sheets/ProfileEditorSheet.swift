//
//  ProfileEditorSheet.swift
//  ICNS
//
//  Created by Ioannis Notaris on 9/1/26.
//

import SwiftUI

struct ProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var profileStore: ProfileStore
    
    let editingProfile: ExportProfile?
    
    @State private var profileName: String
    @State private var sizes: [Int]
    @State private var newSizeText: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    init(profileStore: ProfileStore, editingProfile: ExportProfile? = nil) {
        self.profileStore = profileStore
        self.editingProfile = editingProfile
        
        _profileName = State(initialValue: editingProfile?.name ?? "")
        _sizes = State(initialValue: editingProfile?.sizes ?? [])
    }
    
    private var isValid: Bool {
        !profileName.trimmingCharacters(in: .whitespaces).isEmpty && !sizes.isEmpty
    }
    
    private var isEditing: Bool {
        editingProfile != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Profile" : "New Profile")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(isEditing ? "Save" : "Create") {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
            
            Divider()
            
            // Content
            Form {
                Section("Identity") {
                    TextField("Profile Name", text: $profileName)
                        .disabled(editingProfile?.isDefault == true)
                    
                    if editingProfile?.isDefault == true {
                        Text("Default profile name cannot be changed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    // Existing sizes list
                    if !sizes.isEmpty {
                        List {
                            ForEach(Array(sizes.enumerated()), id: \.element) { index, size in
                                HStack {
                                    Image(systemName: "square.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(size) × \(size) px")
                                    
                                    Spacer()
                                    
                                    Button {
                                        withAnimation {
                                            let indexToRemove = index
                                            sizes.remove(at: indexToRemove)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove this size")
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(height: min(CGFloat(sizes.count * 32), 200))
                    } else {
                        Text("No sizes added yet")
                            .foregroundStyle(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    
                    // Add new size
                    HStack {
                        TextField("Size (e.g. 512)", text: $newSizeText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addSize()
                            }
                        
                        Button {
                            addSize()
                        } label: {
                            Label("Add Size", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(newSizeText.isEmpty)
                    }
                } header: {
                    Text("Icon Sizes")
                } footer: {
                    Text("Add icon sizes in pixels (e.g., 16, 32, 64, 128, 256, 512, 1024)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 500, height: 550)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addSize() {
        guard let size = Int(newSizeText.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Please enter a valid number"
            showError = true
            return
        }
        
        guard size > 0 else {
            errorMessage = "Size must be greater than 0"
            showError = true
            return
        }
        
        guard !sizes.contains(size) else {
            errorMessage = "This size already exists in the profile"
            showError = true
            return
        }
        
        withAnimation {
            sizes.append(size)
            sizes.sort()
        }
        newSizeText = ""
    }
    
    private func saveProfile() {
        let trimmedName = profileName.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Profile name cannot be empty"
            showError = true
            return
        }
        
        guard !sizes.isEmpty else {
            errorMessage = "Profile must have at least one size"
            showError = true
            return
        }
        
        if let editing = editingProfile {
            // Update existing profile
            let updated = ExportProfile(
                id: editing.id,
                name: trimmedName,
                sizes: sizes,
                isDefault: editing.isDefault
            )
            profileStore.updateProfile(updated)
        } else {
            // Create new profile
            let newProfile = ExportProfile(
                name: trimmedName,
                sizes: sizes,
                isDefault: false
            )
            profileStore.addProfile(newProfile)
        }
        
        dismiss()
    }
}
