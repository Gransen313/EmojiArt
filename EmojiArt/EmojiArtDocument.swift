//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Sergey Borisov on 05.04.2021.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    
    static let pallet: String = "👀🧞‍♂️🪡🦀🎂"
    
    //@Published// workaround for property observer problem with property wrapper
    private var emojiArt: EmojiArt {
        willSet {
            objectWillChange.send()
        }
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
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
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }
}

