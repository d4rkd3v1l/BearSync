//
//  SecureInputField.swift
//  BearSync
//
//  Created by d4Rk on 22.10.24.
//

import SwiftUI

@MainActor @preconcurrency
struct SecureRevealableField: View {

    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    private var prompt: Text?

    init(_ title: String, text: Binding<String>, prompt: Text? = nil) {
        self.title = title
        self._text = text
        self.prompt = prompt
    }

    var body: some View {
        HStack {
            Group {
                if isSecured {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textFieldStyle(.roundedBorder)
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }
    }
}
