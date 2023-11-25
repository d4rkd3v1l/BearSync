//
//  SettingsView.swift
//  BearAppSync
//
//  Created by d4Rk on 24.11.23.
//

import SwiftUI
import KeychainAccess

struct SettingsView: View {
    @Preference(\.instanceId) var instanceId
    @Preference(\.bearAPIToken) var bearAPIToken
    @Preference(\.gitRepoURL) var gitRepoURL
    @Preference(\.tags) var tags
    @State var gitRepoPath: URL?

    var body: some View {
        Form {
            HStack {
                TextField("Instance ID:",
                          text: Binding(get: { instanceId }, set: { _ in }),
                          prompt: Text("Missing"))
                .disabled(true)
                Button("Copy") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(instanceId, forType: .string)
                }
            }
            Text("The Instance ID of this BearAppSync installation.")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            SecureField("Bear API Token:",
                        text: $bearAPIToken,
                        prompt: Text("Required"))
            Text("Bear → Help → Advanced → API Token")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            SecureField("Git repo URL:",
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
        .padding()
        .frame(width: 500)
        .fixedSize()
        .onAppear {
            gitRepoPath = try? OpenPanelHelper().getURL(for: Constants.UserDefaultsKey.gitRepoPathBookmark.rawValue)
        }
    }
}
