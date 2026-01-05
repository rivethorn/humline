import Foundation

struct SomaFMResponse: Codable {
    let channels: [Channel]
}

struct Channel: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let dj: String
    let djmail: String
    let genre: String
    let image: URL
    let largeimage: URL
    let xlimage: URL
    let twitter: String?
    let updated: String
    let playlists: [Playlist]
    let preroll: [URL]
    let listeners: String
    let lastPlaying: String
    let featured: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, dj, djmail, genre, image, largeimage, xlimage, twitter, updated, playlists, preroll, listeners, lastPlaying, featured
    }
}

struct Playlist: Codable, Identifiable {
    let url: URL
    let format: String
    let quality: String
    
    var id: String { url.absoluteString }
}