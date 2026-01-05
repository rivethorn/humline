//
//  StreamPlayer.swift
//  humline
//
//  Created by Hassan Qasemi on 2026-01-05.
//


import Foundation
import Combine
import AVFoundation

final class StreamPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var errorMessage: String?
    @Published var currentChannelTitle: String?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var bag = Set<AnyCancellable>()
    private var timeObserver: Any?

    init() {
        // No audio session setup needed for macOS
    }

    func toggle(channel: any Identifiable & Sendable, title: String, playlistURL: URL) async {
        if isPlaying && currentChannelTitle == title {
            stop()
        } else {
            await start(title: title, playlistURL: playlistURL)
        }
    }

    func start(title: String, playlistURL: URL) async {
        await MainActor.run {
            currentChannelTitle = title
            errorMessage = nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: playlistURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                await MainActor.run {
                    errorMessage = "HTTP error fetching playlist"
                }
                return
            }
            
            let content = String(data: data, encoding: .utf8) ?? ""
            guard let streamURL = parsePLSContent(content) else {
                await MainActor.run {
                    errorMessage = "Failed to parse playlist"
                }
                return
            }
            
            await MainActor.run {
                playerItem = AVPlayerItem(url: streamURL)
                player = AVPlayer(playerItem: playerItem)
                
                NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
                    .sink { [weak self] _ in
                        Task { @MainActor in
                            self?.stop()
                        }
                    }
                    .store(in: &bag)
                
                player?.play()
                isPlaying = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func parsePLSContent(_ content: String) -> URL? {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("File1=") {
                let urlString = String(line.dropFirst(6))
                return URL(string: urlString)
            }
        }
        
        return nil
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        isPlaying = false
        currentChannelTitle = nil
    }
}

