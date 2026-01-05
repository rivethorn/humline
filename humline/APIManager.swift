import Foundation
import Combine

@MainActor
class APIManager: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL = "https://api.somafm.com/channels.json"
    
    func fetchChannels() async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: baseURL) else {
                throw APIError.invalidURL
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SomaFMResponse.self, from: data)
            channels = response.channels.sorted { $0.title < $1.title }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        }
    }
}