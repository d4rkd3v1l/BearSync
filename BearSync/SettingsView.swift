//
//  SettingsView.swift
//  BearSync
//
//  Created by d4Rk on 24.11.23.
//

import SwiftUI
import KeychainAccess

struct SettingsView: View {
    @Preference(\.clientId) var clientId
    @Preference(\.bearAPIToken) var bearAPIToken
    @Preference(\.gitRepoURL) var gitRepoURL
    @Preference(\.tags) var tags
    @Preference(\.useSQLite) var useSQLite
    @State var gitRepoPath: URL?

    var body: some View {
        Form {
            HStack {
                TextField("Client Name:",
                          text: $clientId,
                          prompt: Text("Enter a name or description here."))
            }
            Text("The name of this client, used as git author to identify clients.")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            SecureRevealableField("Bear API Token:",
                                  text: $bearAPIToken,
                                  prompt: Text("Required"))

            Text("Bear → Help → Advanced → API Token")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            SecureRevealableField("Git repo URL:",
                                  text: $gitRepoURL,
                                  prompt: Text("Required"))
            Text("The remote URL of the git repo, used for synchronizing.\nE.g. \"https://<token>@github.com/<user>/bear-sync.git\"")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            HStack {
                TextField("Git repo directory:",
                          text: Binding(get: { gitRepoPath?.path() ?? "" }, set: { _ in }),
                          prompt: Text("Required"))
                .disabled(true)
                Button("Choose") {
                    Task {
                        gitRepoPath = try await OpenPanelHelper().openDirectory(at: nil, bookmark: Constants.UserDefaultsKey.gitRepoPathBookmark.rawValue)
                    }
                }
            }
            Text("The local path of the git repo, used for synchronizing.\nE.g. \"/Users/<name>/bear-sync\"")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            TextField("Tags:",
                      text: Binding(get: { tags.joined(separator: " ") }, set: { tags = $0.components(separatedBy: " ") }),
                      prompt: Text("Required"))
            Text("Tags to be included in the synchronization process. Multiple tags must be seperated by spaces.\nE.g. \"tag1 tag2 tag3\"")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            Toggle("Use SQLite:",
                   isOn: $useSQLite)
            .toggleStyle(.switch)
            Text("Using SQLite for some read operations will remove flickering and focus change during sync. However, this is not officially supported by Bear App and therefore may lead to issues.")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

#if DEBUG
            Spacer()
            Spacer()
            Spacer()

            Button("RESET") {
                try! Keychain().removeAll()
                UserDefaults.standard.removeObject(forKey: Constants.PreferencesKey.tags.rawValue)
                UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKey.gitRepoPathBookmark.rawValue)
            }
            #endif
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .frame(width: 500)
        .fixedSize()
        .onAppear {
            gitRepoPath = try? OpenPanelHelper().getURL(for: Constants.UserDefaultsKey.gitRepoPathBookmark.rawValue)
        }
    }
}
