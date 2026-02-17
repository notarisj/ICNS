//
//  FocusedValues+ICNS.swift
//  ICNS
//
//  Created by Assistant on 3/2/26.
//

import SwiftUI

struct SearchFocusKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var searchFocus: Binding<Bool>? {
        get { self[SearchFocusKey.self] }
        set { self[SearchFocusKey.self] = newValue }
    }
}
