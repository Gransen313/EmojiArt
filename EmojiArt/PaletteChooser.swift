//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Sergey Borisov on 06.05.2021.
//

import SwiftUI

struct PaletteChooser: View {
    
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var choosenPalette: String
    @State private var showPaletteEditor = false
    
    var body: some View {
        HStack {
            Stepper(onIncrement: {
                choosenPalette = document.palette(after: choosenPalette)
            }, onDecrement: {
                choosenPalette = document.palette(before: choosenPalette)
            }, label: { EmptyView() })
            Text(document.paletteNames[choosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    showPaletteEditor = true
                }
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(choosenPalette: $choosenPalette, isShowing: $showPaletteEditor)
                        .environmentObject(self.document)
                        .frame(minWidth: 300, minHeight: 500)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    
    @EnvironmentObject var document: EmojiArtDocument
    
    @Binding var choosenPalette: String
    @Binding var isShowing: Bool
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor").font(.headline).padding()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowing = false
                    }, label: { Text("Done") }).padding()
                }
            }
            Divider()
            Form {
                Section {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            document.renamePalette(choosenPalette, to: paletteName)
                        }
                    })
                    TextField("Add Emojis", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            choosenPalette = document.addEmoji(emojisToAdd, toPalette: choosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    Grid(choosenPalette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji).font(Font.system(size: fontSize))
                            .onTapGesture {
                                choosenPalette = document.removeEmoji(emoji, fromPalette: choosenPalette)
                            }
                    }
                    .frame(height: height)
                }
            }
        }
        .onAppear { paletteName = document.paletteNames[choosenPalette] ?? "" }
    }
    
    //MARK: - Drawing constants
    
    private var height: CGFloat {
        CGFloat((choosenPalette.count - 1) / 6 * 70 + 70)
    }
    private let fontSize: CGFloat = 40.0
}







struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), choosenPalette: Binding.constant(""))
    }
}
