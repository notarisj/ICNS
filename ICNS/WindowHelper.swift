//
//  WindowHelper.swift
//  ICNS
//
//  Created by Ioannis Notaris on 6/1/25.
//

import SwiftUI

struct WindowHelper {
    /// Toggles the inspector with automatic window resize if needed
    /// - Parameter showInspector: Binding to the inspector visibility state
    static func toggleInspectorWithResize(_ showInspector: Binding<Bool>) {
        // If we're turning the inspector on, check window size first
        if !showInspector.wrappedValue {
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
                showInspector.wrappedValue.toggle()
                return
            }
            
            // Get the window's actual minimum allowed width
            // If not set, use a calculated minimum based on layout requirements
            let inspectorWidth = getInspectorWidth(from: window.contentView ?? NSView()) ?? 250
            let minRequiredWidth: CGFloat = window.minSize.width > 0 ? window.minSize.width + inspectorWidth + 38 : 900
            let currentFrame = window.frame
            print(window.minSize.width)
            
            if currentFrame.width < minRequiredWidth {
                // Calculate new frame maintaining the same top-left position
                var newFrame = currentFrame
                newFrame.size.width = minRequiredWidth
                
                // Ensure window doesn't go off screen
                if let screen = window.screen {
                    let screenFrame = screen.visibleFrame
                    if newFrame.maxX > screenFrame.maxX {
                        newFrame.origin.x = screenFrame.maxX - newFrame.width
                    }
                }
                
                // Animate the resize
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setFrame(newFrame, display: true)
                }, completionHandler: {
                    // Toggle inspector after resize completes
                    DispatchQueue.main.async {
                        showInspector.wrappedValue.toggle()
                    }
                })
            } else {
                showInspector.wrappedValue.toggle()
            }
        } else {
            // Turning inspector off - just toggle
            showInspector.wrappedValue.toggle()
        }
    }
    
    /// Recursively searches the view hierarchy to find the inspector's actual width
    /// - Parameter view: The view to search from
    /// - Returns: The inspector's width if found, nil otherwise
    private static func getInspectorWidth(from view: NSView) -> CGFloat? {
        // Check if this is a split view
        if let splitView = view as? NSSplitView {
            // The inspector is typically the last arranged subview in the split view
            if let lastItem = splitView.arrangedSubviews.last,
               splitView.arrangedSubviews.count > 1 {
                // Return the width of the last split item (inspector)
                return lastItem.frame.width
            }
        }
        
        // Recursively search subviews
        for subview in view.subviews {
            if let width = getInspectorWidth(from: subview) {
                return width
            }
        }
        
        return nil
    }
}
