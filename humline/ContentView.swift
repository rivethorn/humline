//
//  ContentView.swift
//  humline
//
//  Created by Hassan Qasemi on 2026-01-04.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var player = StreamPlayer()

    var body: some View {
        VStack(spacing: 16) {
            Text("SomaFM – Groove Salad")

            Button(action: { player.toggle() }) {
                Text(player.isPlaying ? "Stop" : "Play")
                    .font(.title)
                    .padding(4)
            }
            .cornerRadius(100)
            .glassEffect(.regular.tint(.accentColor).interactive())

            if let error = player.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
