//
//  ExportProfilesView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 9/1/26.
//

import SwiftUI

struct ExportProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var profileStore: ProfileStore
    
    @State private var showProfileEditor = false
    @State private var editingProfile: ExportProfile? = nil
    @State private var showDeleteConfirmation = false
    @State private var profileToDelete: ExportProfile? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Profiles")
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            // Profile List
            if profileStore.profiles.isEmpty {
                ContentUnavailableView(
                    "No Profiles",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("Create a profile to get started")
                )
            } else {
                List {
                    ForEach(profileStore.profiles) { profile in
                        HStack(spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(profile.isDefault ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: profile.isDefault ? "star.fill" : "square.stack.3d.up")
                                    .font(.system(size: 14))
                                    .foregroundStyle(profile.isDefault ? Color.accentColor : Color.secondary)
                            }
                            
                            // Profile Info
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(profile.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    if profile.isDefault {
                                        Text("DEFAULT")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor, in: Capsule())
                                    }
                                }
                                
                                Text(profile.sizesDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                // Size details
                                Text(profile.sizes.map { "\($0)" }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                editingProfile = profile
                                showProfileEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                profileToDelete = profile
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(profile.isDefault)
                        }
                    }
                }
                .listStyle(.inset)
            }
            
            Divider()
            
            // Footer with Add Button
            HStack {
                Spacer()
                
                Button {
                    editingProfile = nil
                    showProfileEditor = true
                } label: {
                    Label("Add Profile", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
        .frame(width: 550, height: 450)
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditorSheet(profileStore: profileStore, editingProfile: editingProfile)
        }
        .alert("Delete Profile", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let profile = profileToDelete {
                    profileStore.deleteProfile(profile)
                }
            }
        } message: {
            if let profile = profileToDelete {
                Text("Are you sure you want to delete the profile '\(profile.name)'? This action cannot be undone.")
            }
        }
    }
}
