import Foundation
import Combine

@MainActor
class PlaylistManager: ObservableObject {
    @Published var streamURL: URL?
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchStreamURL(from playlistURL: URL) async {
        isLoading = true
        error = nil
        
        do {
            let (data, _) = try await URLSession.shared.data(from: playlistURL)
            let content = String(data: data, encoding: .utf8) ?? ""
            streamURL = parsePLSContent(content)
        } catch {
            self.error = error
        }
        
        isLoading = false
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
}