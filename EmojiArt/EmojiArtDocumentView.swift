//
//  ContentView.swift
//  EmojiArt
//
//  Created by Sergey Borisov on 05.04.2021.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    @ObservedObject var document: EmojiArtDocument
    
    @State private var selectedEmogies = Set<EmojiArt.Emoji>()
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.pallet.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    ForEach(document.emojies) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emoji.fontSize * zoomScale)
                            .position(self.position(for: emoji, in: geometry.size))
                            .opacity(isSelected(emoji) ? 0.5 : 1.0)
                            .onTapGesture {
                                selectedEmogies.toggleMatching(emoji)
                                print("\(selectedEmogies.contains(matching: emoji))  \(emoji.text)")
                            }
                            .gesture(emogiesDragGesture(emoji))
                    }
                }
                .clipped()
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
//                    var location = geometry.convert(location, from: .global)
                    
                    // SwiftUI bug (as of 13.4)? the location is supposed to be in our coordinate system
                    // however, the y coordinate appears to be in the global coordinate system
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .gesture(deselectAllEmogies(in: geometry.size))
            }
        }
    }
    
//    @State private var steadyStateSelectedEmogiesOffset: CGSize = .zero
    @GestureState private var gestureSelectedEmogiesOffset: CGSize = .zero
    
//    private var emogiesDragOffset: CGSize {
//        (steadyStateSelectedEmogiesOffset + gestureSelectedEmogiesOffset) * zoomScale
//    }
    
    private func emogiesDragGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureSelectedEmogiesOffset) { latestDragGestureValue, gestureSelectedEmogiesOffset, transaction in
                gestureSelectedEmogiesOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalEmogiesDragValue in
                let dragDistance = finalEmogiesDragValue.translation / zoomScale
                selectedEmogies.forEach { emoji in
                    document.moveEmoji(emoji, by: dragDistance)
                    selectedEmogies.remove(emoji)
                    selectedEmogies.insert(emoji)
                }
//                steadyStateSelectedEmogiesOffset = steadyStateSelectedEmogiesOffset + finalEmogiesDragValue.translation / zoomScale
            }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + finalDragGestureValue.translation / zoomScale
            }
    }
    
    private func isSelected(_ emoji: EmojiArt.Emoji) -> Bool {
        selectedEmogies.contains(matching: emoji)
    }
    
    private func deselectAllEmogies(in size: CGSize) -> some Gesture {
        TapGesture(count: 1)
            .exclusively(before: doubleTapToZoom(in: size))
            .onEnded { _ in
                withAnimation {
                    selectedEmogies.removeAll()
                }
            }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                steadyStateZoomScale *= finalGestureScale
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hScale = size.width / image.size.width
            let vScale = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hScale, vScale)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if selectedEmogies.contains(matching: emoji) {
            location = CGPoint(x: location.x + gestureSelectedEmogiesOffset.width * zoomScale, y: location.y + gestureSelectedEmogiesOffset.height * zoomScale)
        }
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}







//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmojiArtDocumentView(document: EmojiArtDocument())
//    }
//}
