//
//  ProfilePicker.swift
//  ICNS
//
//  Created by Ioannis Notaris on 9/1/26.
//

import SwiftUI

struct ProfilePicker: View {
    @Binding var selectedProfileID: UUID?
    let profiles: [ExportProfile]
    
    private var selectedProfile: ExportProfile? {
        if let id = selectedProfileID {
            return profiles.first(where: { $0.id == id })
        }
        return profiles.first(where: { $0.isDefault })
    }
    
    var body: some View {
        Picker("Profile", selection: Binding(
            get: { selectedProfileID ?? profiles.first(where: { $0.isDefault })?.id ?? UUID() },
            set: { selectedProfileID = $0 }
        )) {
            ForEach(profiles) { profile in
                HStack {
                    Text(profile.name)
                    if profile.isDefault {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("Default")
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(profile.id)
            }
        }
        .pickerStyle(.menu)
        
        if let profile = selectedProfile {
            Text(profile.sizesDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
