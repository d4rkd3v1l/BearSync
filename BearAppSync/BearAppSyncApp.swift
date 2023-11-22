//
//  BearAppSyncApp.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            Synchronizer.shared.handleURL(url)
        }
    }
}

@main
struct BearAppSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var icon = "arrow.triangle.2.circlepath"

    @State var settingsWindow: NSWindow?

    var body: some Scene {
        MenuBarExtra("Bear App Sync", systemImage: icon) {
            Button("Synchronize") {
                Task {
                    do {
                        icon = "clock.arrow.2.circlepath"
                        try await Synchronizer.shared.synchronize()
                        icon = "arrow.triangle.2.circlepath"
                    } catch {
                        icon = "arrow.triangle.2.circlepath"
                        
                        if let syncError = error as? SyncError {
                            switch syncError {
                            case .bearAPITokenNotSet:
                                print("Bear API Token not set -> Settings")
                                
                            case .gitRepoURLNotSet:
                                print("Git Repo URL not set -> Settings")

                            case .syncInProgress:
                                print("Sync already in progress -> Aborting...")
                                
                            case .gitRepoPathNotSet:
                                print("Git Repo Path not set -> Settings")
                            }
                        }
                    }
                }
            }.keyboardShortcut("s")
            
            Divider()

            SettingsLink {
                 Text("Preferences...")
            }.keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
        
        Settings {
            SettingsPane()
//                .background(WindowAccessor(window: $settingsWindow))
//                .onChange(of: settingsWindow) { oldWindow, newWindow in
//                    newWindow?.level = .floating
//                }
        }
    }
}

struct SettingsPane: View {
    @Preference(\.bearAPIToken) var bearAPIToken
    @Preference(\.gitRepoURL) var gitRepoURL
    @Preference(\.tags) var tags
    @State var gitRepoPath: URL?

    var body: some View {
        Form {
            SecureField("Bear API Token:", 
                        text: Binding(get: { bearAPIToken }, set: { bearAPIToken = $0}),
                        prompt: Text("Required"))
            Text("Bear → Help → Advanced → API Token")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            SecureField("Git Repo URL:",
                        text: Binding(get: { gitRepoURL }, set: { gitRepoURL = $0 }),
                        prompt: Text("Required"))
            Text("The remote URL of the git repo, used for synchronizing.\nE.g. \"https://<yourToken>@github.com/<user>/<repo>.git\"")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()

            HStack {
                TextField("Repo folder on disk:",
                          text: Binding(get: { gitRepoPath?.path() ?? "" }, set: { _ in }),
                          prompt: Text("Required"))
                .disabled(true)
                Button("Choose") {
                    Task {
                        gitRepoPath = try await OpenPanelHelper().openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
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

        }
        .padding()
        .frame(width: 500)
        .fixedSize()
        .onAppear {
            gitRepoPath = try? OpenPanelHelper().getURL(for: "gitRepoPathBookmark")
        }
    }
}

/// https://stackoverflow.com/a/77184303/2019384
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
