//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Sergey Borisov on 05.04.2021.
//

import Foundation

struct EmojiArt: Codable {
    var backgroundURL: URL?
    var emojies = [Emoji]()
    
    struct Emoji: Identifiable, Codable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        let id: Int
        
        fileprivate init (text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        } else {
            return nil
        }
    }
    
    init() {  }
    
    private var uniqueEmojiID = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiID += 1
        emojies.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiID))
    }
}
