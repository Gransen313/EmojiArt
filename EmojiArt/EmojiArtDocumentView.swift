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
    @State private var dragingNowEmoji: EmojiArt.Emoji?
    @State private var choosenPalette: String = ""
    
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, choosenPalette: $choosenPalette)
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(choosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear { choosenPalette = document.defaultPalette }
                
                Button(action: {
                    selectedEmogies.forEach { emoji in
                        selectedEmogies.remove(emoji)
                        document.removeEmoji(emoji)
                    }
                }, label: {
                    Image(systemName: "trash.fill")
                        .font(.title)
                })
                .padding(.trailing)
                .disabled(selectedEmogies.isEmpty)
            }
            
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    if isLoading {
                        Image(systemName: "timer").imageScale(.large).spinning()
                    } else {
                        ForEach(document.emojies) { emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * zoomScale(for: emoji))
                                .position(self.position(for: emoji, in: geometry.size))
                                .opacity(isSelected(emoji) ? 0.7 : 1.0)
                                .onTapGesture {
                                    selectedEmogies.toggleMatching(emoji)
                                }
                                .gesture(emogiesDragGesture(emoji))
                        }
                    }
                }
                .clipped()
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(self.document.$backgroundImage) { image in
                    self.zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
//                    var location = geometry.convert(location, from: .global)
                    var location = CGPoint(x: location.x, y: location.y)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .gesture(deselectAllEmogies(in: geometry.size))
            }
        }
    }
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    @GestureState private var gestureSelectedEmogiesOffset: CGSize = .zero
    
    private func emogiesDragGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        return DragGesture()
            .updating($gestureSelectedEmogiesOffset) { latestDragGestureValue, gestureSelectedEmogiesOffset, transaction in
                gestureSelectedEmogiesOffset = latestDragGestureValue.translation / zoomScale
            }
            .onChanged { _ in
                if !isSelected(emoji) {
                    dragingNowEmoji = emoji
                }
            }
            .onEnded { finalEmogiesDragValue in
                dragingNowEmoji = nil
                let dragDistance = finalEmogiesDragValue.translation / zoomScale
                if isSelected(emoji)  {
                    selectedEmogies.forEach { emoji in
                        document.moveEmoji(emoji, by: dragDistance)
                    }
                } else {
                    document.moveEmoji(emoji, by: dragDistance)
                }
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
        steadyStateZoomScale * (selectedEmogies.isEmpty ? gestureZoomScale : 1.0)
    }
    
    private func zoomScale(for emoji: EmojiArt.Emoji) -> CGFloat {
        isSelected(emoji) ? (steadyStateZoomScale * gestureZoomScale) : zoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                if selectedEmogies.isEmpty {
                    steadyStateZoomScale *= finalGestureScale
                } else {
                    selectedEmogies.forEach { emoji in
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
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
        if selectedEmogies.contains(matching: emoji) && dragingNowEmoji == nil {
            location = CGPoint(x: location.x + gestureSelectedEmogiesOffset.width * zoomScale, y: location.y + gestureSelectedEmogiesOffset.height * zoomScale)
        }
        if emoji == dragingNowEmoji {
            location = CGPoint(x: location.x + gestureSelectedEmogiesOffset.width * zoomScale, y: location.y + gestureSelectedEmogiesOffset.height * zoomScale)
        }
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.backgroundURL = url
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
