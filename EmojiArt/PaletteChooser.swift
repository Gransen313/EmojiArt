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
    
    var body: some View {
        HStack {
            Stepper(onIncrement: {
                choosenPalette = document.palette(after: choosenPalette)
            }, onDecrement: {
                choosenPalette = document.palette(before: choosenPalette)
            }, label: { EmptyView() })
            Text(document.paletteNames[choosenPalette] ?? "")
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), choosenPalette: Binding.constant(""))
    }
}
