//
//  StreamPlayer.swift
//  humline
//
//  Created by Hassan Qasemi on 2026-01-05.
//


import Foundation
import Combine
import ChunkedAudioPlayer
import AVFoundation

final class StreamPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var errorMessage: String?

    private let url = URL(string: "http://ice1.somafm.com/groovesalad-128-mp3")! // SomaFM Groove Salad [web:8]
    private let player = AudioPlayer()                                            // from ChunkedAudioPlayer [web:7]
    private var bag = Set<AnyCancellable>()
    private var task: Task<Void, Never>?

    init() {
        player.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isPlaying = (state == .playing)
            }
            .store(in: &bag)

        player.$currentError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] err in
                self?.errorMessage = err?.localizedDescription
            }
            .store(in: &bag)
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard task == nil else { return }

        // Simple async byte stream from URLSession
        task = Task {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    await MainActor.run {
                        self.errorMessage = "HTTP error"
                    }
                    return
                }

                let stream = AsyncThrowingStream<Data, Error>(bufferingPolicy: .unbounded) { (continuation: AsyncThrowingStream<Data, Error>.Continuation) in
                    Task.detached {
                        do {
                            var buffer = Data()
                            buffer.reserveCapacity(4096)
                            for try await byte in bytes {
                                buffer.append(byte)
                                if buffer.count >= 4096 {
                                    continuation.yield(buffer)
                                    buffer.removeAll(keepingCapacity: true)
                                }
                            }
                            if !buffer.isEmpty {
                                continuation.yield(buffer)
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                }

                // MP3 stream type hint for the player [web:7]
                player.start(stream, type: kAudioFileMP3Type)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        player.stop()
        isPlaying = false
    }
}

