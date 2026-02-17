//
//  SearchFieldView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 17/2/24.
//

import SwiftUI
import AppKit

struct SearchFieldView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    func makeNSView(context: Context) -> MySearchField {
        let searchField = MySearchField()
        searchField.delegate = context.coordinator
        searchField.bezelStyle = .roundedBezel
        searchField.onCancel = {
            // Unfocus and close
            searchField.window?.makeFirstResponder(nil)
            isSearching = false
        }
        return searchField
    }
    
    func updateNSView(_ nsView: MySearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        // Track if we need to focus
        let needsFocus = isSearching && !context.coordinator.hasFocused
        
        // Auto-focus logic - more aggressive focusing when search is activated
        if needsFocus {
            context.coordinator.hasFocused = true
            // Use a slight delay to ensure the view is fully in the hierarchy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                nsView.window?.makeFirstResponder(nsView)
            }
        } else if !isSearching {
            // Reset the flag when search is closed
            context.coordinator.hasFocused = false
        }
    }
    
    static func dismantleNSView(_ nsView: MySearchField, coordinator: Coordinator) {
        nsView.delegate = nil
        coordinator.isValid = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isSearching: $isSearching)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String
        @Binding var isSearching: Bool
        var hasFocused = false
        var isValid = true
        
        init(text: Binding<String>, isSearching: Binding<Bool>) {
            _text = text
            _isSearching = isSearching
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard isValid else { return }
            if let searchField = obj.object as? NSSearchField {
                // Only update if actually changed to avoid redundant updates
                if text != searchField.stringValue {
                    let newValue = searchField.stringValue
                    DispatchQueue.main.async {
                        self.text = newValue
                    }
                }
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard isValid else { return }
            // If empty when editing ends, collapse
            if text.isEmpty {
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            }
        }
    }
}

class MySearchField: NSSearchField {
    var onCancel: (() -> Void)?
    
    override func cancelOperation(_ sender: Any?) {
        if stringValue.isEmpty {
            onCancel?()
        } else {
            stringValue = ""
            // Notify delegate manually since programmatic change doesn't always trigger it
            if let delegate = delegate {
                DispatchQueue.main.async {
                    delegate.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: self))
                }
            }
        }
    }
}

#Preview {
    SearchFieldView(text: .constant("Search"), isSearching: .constant(true))
        .frame(width: 180)
        .padding()
}
