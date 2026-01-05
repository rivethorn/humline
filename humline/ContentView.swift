//
//  ContentView.swift
//  humline
//
//  Created by Hassan Qasemi on 2026-01-04.
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case main = "Main"
    case favorites = "Favorites"

    var id: String { rawValue }
    var title: String { rawValue }
    var systemImage: String {
        switch self {
        case .main: return "music.note.list"
        case .favorites: return "star"
        }
    }
}

struct ContentView: View {
    @StateObject private var player = StreamPlayer()
    @StateObject private var apiManager = APIManager()
    @State private var selection: SidebarItem? = .main

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) {
                Label($0.title, systemImage: $0.systemImage)
            }
            .navigationTitle("humline")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection ?? .main {
                case .main:
                    mainView
                case .favorites:
                    favoritesView
                }
            }
            .navigationTitle(selection?.title ?? "Main")
        }
    }

    private var mainView: some View {
        Group {
            if apiManager.isLoading {
                ProgressView("Loading channels...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = apiManager.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Failed to load channels")
                        .font(.title2)
                        .bold()
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task {
                            await apiManager.fetchChannels()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if apiManager.channels.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("No channels available")
                        .font(.title2)
                        .bold()
                    Text("Unable to load SomaFM channels")
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task {
                            await apiManager.fetchChannels()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300, maximum: 400))
                    ], spacing: 16) {
                        ForEach(apiManager.channels) { channel in
                            ChannelCard(channel: channel, player: player)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await apiManager.fetchChannels()
        }
    }

    private var favoritesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("Favorites")
                .font(.title2)
                .bold()
            Text("You don't have any favorites yet.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}

struct ChannelCard: View {
    let channel: Channel
    @ObservedObject var player: StreamPlayer
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: channel.xlimage) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            }
            .frame(height:380)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(channel.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(channel.listeners) listeners")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    Text(channel.genre)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            Button(action: {
                Task {
                    isLoading = true
                    guard let playlistURL = channel.playlists.first?.url else {
                        await MainActor.run {
                            player.errorMessage = "No playlist URL found for this channel"
                        }
                        isLoading = false
                        return
                    }
                    await player.toggle(
                        channel: channel,
                        title: channel.title,
                        playlistURL: playlistURL
                    )
                    isLoading = false
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if player.isPlaying && player.currentChannelTitle == channel.title {
                        Image(systemName: "stop.fill")
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(player.isPlaying && player.currentChannelTitle == channel.title ? "Playing" : "Play")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .cornerRadius(100)
            .disabled(isLoading)
            .controlSize(.small)
            .glassEffect(.clear.tint(.accentColor).interactive())
            
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
