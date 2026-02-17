//
//  ProfileStore.swift
//  ICNS
//
//  Created by Ioannis Notaris on 9/1/26.
//

import SwiftUI
import Combine
import OSLog

class ProfileStore: ObservableObject {
    @Published var profiles: [ExportProfile] = [] {
        didSet {
            saveProfiles()
        }
    }
    
    var defaultProfile: ExportProfile {
        profiles.first(where: { $0.isDefault }) ?? ExportProfile.createDefault()
    }
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Persistence
    
    private func loadProfiles() {
        if let savedProfilesData = UserDefaults.standard.data(forKey: "exportProfiles") {
            do {
                let savedProfiles = try JSONDecoder().decode([ExportProfile].self, from: savedProfilesData)
                self.profiles = savedProfiles
                
                // Ensure default profile exists
                if !profiles.contains(where: { $0.isDefault }) {
                    profiles.insert(ExportProfile.createDefault(), at: 0)
                }
            } catch {
                Logger.data.error("Error decoding profiles: \(error, privacy: .public)")
                initializeDefaultProfile()
            }
        } else {
            initializeDefaultProfile()
        }
    }
    
    private func saveProfiles() {
        do {
            let profilesData = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(profilesData, forKey: "exportProfiles")
        } catch {
            Logger.data.error("Error encoding profiles: \(error, privacy: .public)")
        }
    }
    
    private func initializeDefaultProfile() {
        profiles = [ExportProfile.createDefault()]
    }
    
    // MARK: - Actions
    
    func addProfile(_ profile: ExportProfile) {
        profiles.append(profile)
    }
    
    func updateProfile(_ profile: ExportProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
    }
    
    func deleteProfile(_ profile: ExportProfile) {
        // Prevent deleting the default profile
        guard !profile.isDefault else { return }
        profiles.removeAll(where: { $0.id == profile.id })
    }
    
    func getProfile(byID id: UUID?) -> ExportProfile {
        guard let id = id else { return defaultProfile }
        return profiles.first(where: { $0.id == id }) ?? defaultProfile
    }
}
