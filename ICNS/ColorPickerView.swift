//
//  ColorPickerView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: CategoryColor
    
    let columns = [
        GridItem(.adaptive(minimum: 50), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CategoryColor.allCases) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                            
                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help(color.displayName)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ColorPickerView(selectedColor: .constant(.blue))
}
