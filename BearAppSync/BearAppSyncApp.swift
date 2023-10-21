//
//  BearAppSyncApp.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI

@main
struct BearAppSyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"]) // activate existing window if exists
                .onOpenURL(perform: { url in
                    print("\(url)") // This is just debug code
                    // bearappsync://x-callback-url/createSuccess?fileId=4F5C579C-62B6-40B8-9DFD-07DAEDD166EA&title=new%20file&identifier=95F34216-5CE2-4FB5-8921-C955D3E5B194&
                })
        }.commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
        .handlesExternalEvents(matching: ["*"]) // create new window if doesn't exist
    }
}
