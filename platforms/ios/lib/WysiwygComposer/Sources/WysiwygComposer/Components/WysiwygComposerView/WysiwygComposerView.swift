//
// Copyright 2022 The Matrix.org Foundation C.I.C
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import OSLog
import SwiftUI

/// Provides a SwiftUI displayable view for the composer UITextView component.
public struct WysiwygComposerView: UIViewRepresentable {
    // MARK: - Internal

    public var viewModel: WysiwygComposerViewModel
    
    private var tintColor = Color.accentColor
    private var placeholderColor = Color(UIColor.placeholderText)
    private var placeholder: String?
    @Binding public var focused: Bool

    public init(focused: Binding<Bool>,
                viewModel: WysiwygComposerViewModel) {
        _focused = focused
        self.viewModel = viewModel
    }
    
    public func makeUIView(context: Context) -> PlaceholdableTextView {
        let textView = PlaceholdableTextView()
        
        textView.accessibilityIdentifier = "WysiwygComposer"
        textView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        textView.autocapitalizationType = .sentences
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.delegate = context.coordinator
        textView.textStorage.delegate = context.coordinator
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.tintColor = UIColor(tintColor)
        textView.placeholderFont = UIFont.preferredFont(forTextStyle: .subheadline)
        textView.placeholderColor = UIColor(placeholderColor)
        textView.placeholder = placeholder
        viewModel.textView = textView
        viewModel.updateCompressedHeightIfNeeded(textView)
        return textView
    }

    public func updateUIView(_ uiView: PlaceholdableTextView, context: Context) {
        uiView.tintColor = UIColor(tintColor)
        uiView.placeholderColor = UIColor(placeholderColor)
        uiView.placeholder = placeholder
        
        switch (focused, uiView.isFirstResponder) {
        case (true, false): uiView.becomeFirstResponder()
        case (false, true): uiView.resignFirstResponder()
        default: break
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator($focused, viewModel.replaceText, viewModel.select, viewModel.didUpdateText)
    }

    /// Coordinates UIKit communication.
    public class Coordinator: NSObject, UITextViewDelegate, NSTextStorageDelegate {
        var focused: Binding<Bool>
        var replaceText: (UITextView, NSRange, String) -> Bool
        var select: (NSAttributedString, NSRange) -> Void
        var didUpdateText: (UITextView) -> Void
        init(_ focused: Binding<Bool>,
             _ replaceText: @escaping (UITextView, NSRange, String) -> Bool,
             _ select: @escaping (NSAttributedString, NSRange) -> Void,
             _ didUpdateText: @escaping (UITextView) -> Void) {
            self.focused = focused
            self.replaceText = replaceText
            self.select = select
            self.didUpdateText = didUpdateText
        }

        public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            Logger.textView.logDebug(["Sel(att): \(range)",
                                      textView.logText,
                                      "Replacement: \"\(text)\""],
                                     functionName: #function)
            return replaceText(textView, range, text)
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            Logger.textView.logDebug([textView.logSelection],
                                     functionName: #function)
            DispatchQueue.main.async {
                self.select(textView.attributedText, textView.selectedRange)
            }
        }
        
        public func textViewDidBeginEditing(_ textView: UITextView) {
            focused.wrappedValue = true
        }
        
        public func textViewDidEndEditing(_ textView: UITextView) {
            focused.wrappedValue = false
        }
        
        public func textViewDidChange(_ textView: UITextView) {
            didUpdateText(textView)
        }
    }
}

public extension WysiwygComposerView {
    /// Sets the tintColor of the WYSIWYG textView, if not used the default value is Color.accent.
    func tintColor(_ tintColor: Color) -> Self {
        var newSelf = self
        newSelf.tintColor = tintColor
        return newSelf
    }
    
    /// Apply a placeholder text to the composer
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder text to display, if nil, no placeholder is displayed.
    ///   - color: The color of the placeholder text when displayed, default value is Color(UIColor.placeholderText).
    func placeholder(_ placeholder: String?, color: Color = Color(UIColor.placeholderText)) -> Self {
        var newSelf = self
        newSelf.placeholder = placeholder
        newSelf.placeholderColor = color
        return newSelf
    }
}

// MARK: - Logger

private extension Logger {
    static let textView = Logger(subsystem: subsystem, category: "TextView")
}
