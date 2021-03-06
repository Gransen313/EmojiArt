//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Sergey Borisov on 05.04.2021.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let pallet: String = "👀🧞‍♂️🪡🦀🎂"
    
    @Published private var emojiArt: EmojiArt
    
    private var autosaveCancelable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        autosaveCancelable = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    
    var emojies: [EmojiArt.Emoji] { emojiArt.emojies }
    
    //MARK: - Intent(s)
    func addEmoji(_ emogi: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emogi, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    func moveEmoji(_ emogi: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojies.firstIndex(matching: emogi) {
            emojiArt.emojies[index].x += Int(offset.width)
            emojiArt.emojies[index].y += Int(offset.height)
        }
    }
    func scaleEmoji(_ emogi: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojies.firstIndex(matching: emogi) {
            emojiArt.emojies[index].size = Int((CGFloat(emojiArt.emojies[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        if let index = emojiArt.emojies.firstIndex(matching: emoji) {
            emojiArt.emojies.remove(at: index)
        }
    }
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    private var fetchImageCancellable: AnyCancellable?
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { data, urlResponse in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }
}

