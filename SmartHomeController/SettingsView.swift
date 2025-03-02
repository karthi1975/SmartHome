//
//  SettingsView.swift
//  SmartHomeController
//
//  Created by karthikeyan jeyabalan on 2/13/25.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("homeAssistantURL") var homeAssistantURL: String = "http://localhost:8123"
    @AppStorage("homeAssistantToken") var homeAssistantToken: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJiOTZkZGU0MGZkNGI0NjEwYTg1MzAyNTA2MzQyZGJhMyIsImlhdCI6MTczOTgyNzU4OCwiZXhwIjoyMDU1MTg3NTg4fQ.l-tm5pnI8Yi4-TwI8hXSVkAJl-HNnvICZvnT-0Ivbj8"
    
    var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Home Assistant Settings")) {
                        TextField("Home Assistant URL", text: $homeAssistantURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        SecureField("Long-Lived Access Token", text: $homeAssistantToken)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .navigationTitle("Settings")
            }
   }
}
