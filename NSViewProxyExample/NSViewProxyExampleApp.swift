//
//  NSViewProxyExampleApp.swift
//  NSViewProxyExample
//
//  Created by Stephan Casas on 6/15/23.
//

import SwiftUI
import Combine;
import NSViewProxy;

@main
struct NSViewProxyExampleApp: App {
    var body: some Scene {
        WindowGroup {
            // MARK: - Custom Titlebar (Replace the Sidebar Button)
            ContentView()
                .proxy(to: .someView(
                    like: /com\.apple\.SwiftUI\.navigationSplitView\.toggleSidebar/
                ), using: { toggleSidebar in
                    /// # Toggle Sidebar Button
                    ///
                    /// Toolbar items yield their identifiers in their debug descriptions,
                    /// and you can use them with the `.someView(like:)` proxy target to
                    /// locate and modify their content.
                    ///
                    guard let nsButton = toggleSidebar.subviews.first else { return }
                    
                    let 🐟 = NSHostingView(rootView: Button(
                        action: { nsButton.window?.title.append(" 🐟") },
                        label: { Image(systemName: "fish.fill") }
                    ));
                    
                    toggleSidebar.addSubview(🐟);
                    🐟.setFrameSize(nsButton.frame.size);
                    🐟.setFrameOrigin(nsButton.frame.origin);
                    
                    /// Visibly hide the original button. SwiftUI seems to
                    /// subscribe on `NSView.subviews` and will re-draw the
                    /// button it goes missing via `NSView.removeFromSuperview(:)`
                    ///
                    nsButton.isHidden = true;
                })
        }
    }
}


struct ContentView: View {
    
    @State var expression: String = """
    You can expose AppKit-only properties in SwiftUI by "proxying" to them in your SwiftUI Views, including:
    
      * Safari-like "New Tab" button
      * Custom or no "Toggle Sidebar" button
      * Auto-save names for `VSplitView` and `HSplitView`
      * Custom tab titles
      * Access to `NSWindow`
      * ... and so much more.
    
    """;
    
    @State var output: String = """
    Setting `autosaveName` on `NSSplitView` ensures your divider positions don't reset every time the app does.
    
    Because proxy callbacks execute pre-draw, your users don't see the flash of unstyled content you'd get by
    using `DispatchQueue.main.async(execute:)`.
    
    Try adding something like a custom insertion point color or change the color of selected text.
    """;
    
    @State var newTabAction: () -> Void = { };
    
    @State var subscriptions: [AnyCancellable] = [];
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List(content: {
                Label("Raincloud", systemImage: "cloud.rain.fill")
                Label("Ceiling Fan", systemImage: "fan.ceiling.fill")
                Label("Bird", systemImage: "bird.fill")
            })
        }, detail: {
            VSplitView(content: {
                TextEditor(text: self.$expression)
                    .font(.body.monospaced())
                
                VStack(spacing: 0, content: {
                    HStack(content: {
                        Text("Result")
                            .font(.body.bold())
                        Spacer()
                    })
                    .padding(.horizontal, 5)
                    .frame(height: 25)
                    
                    // MARK: - Proxy `TextEditor` → to `NSTextView`
                    
                    TextEditor(text: self.$output)
                        .font(.body.monospaced())
                        .proxy(as: NSTextView.self, using: { nsTextView in
                            
                            /// # NSTextView
                            ///
                            /// Modify things like the insertion point color...
                            ///
                            nsTextView.insertionPointColor = .systemPink;
                            ///
                            /// ...or add a custom text highlight color.
                            ///
                            let attrString = NSMutableAttributedString(" ");
                            attrString.addAttributes(
                                nsTextView.selectedTextAttributes,
                                range: NSMakeRange(0, 1));
                            attrString.addAttributes(
                                [NSAttributedString.Key.backgroundColor: NSColor.systemPurple],
                                range: NSMakeRange(0, 1))
                            nsTextView.selectedTextAttributes = attrString.attributes(
                                at: 0, effectiveRange: nil);
                        })
                })
            })
            // MARK: - Proxy `VSplitView` → `NSSplitView`
            .proxy(as: NSSplitView.self, using: { nsSplitView in
                
                /// # NSSplitView
                ///
                /// Assign an autosave name so the divider doesn't reset
                /// on launch, or preemptively set the position using
                /// `nsSplitView.setPosition(position: ofDividerAt:)`.
                ///
                /// Changes take place pre-draw, so your users don't
                /// experience flash of unstyled content.
                ///
                nsSplitView.autosaveName = "com.stephancasas.sampleview.console-split-view";
            })
            .navigationTitle("Sample View")
            // MARK: - Pre-draw `NSWindow` Access
            .proxy(to: .window, using: { nsWindow in
                
                /// # NSTabBar
                ///
                /// Intercept and set the tab bar visibility — before
                /// the `NSWindow` performs its first draw.
                ///
                if (!(nsWindow.tabGroup?.isTabBarVisible ?? false)) {
                    nsWindow.toggleTabBar(nil);
                }
            })
        })
        .toolbar(content: {
            /// # Safari-like New Tab Toolbar Button
            ///
            /// We can use a SwiftUI button in our toolbar. Further down,
            /// we'll capture the native tab button's action and tie it to
            /// our custom button.
            ///
            Button(
                action: self.newTabAction,
                label: { Image(systemName: "plus") }
            ).keyboardShortcut("T", modifiers: .command)
        })
        // MARK: - Custom Tab Button
        .proxy(to: .someView(like: /NSTabBarNewTabButton/), using: { newTabButton in
            
            /// # NSTabBarNewTabButton
            ///
            /// You can use an `NSView`'s class name to find un-documented views
            /// via regular expression, and then upcast those views to access
            /// advanced properties/methods.
            ///
            guard let newTabButton = newTabButton as? NSButton  else { return }
            ///
            /// Use a callback to store actions in a stateful variable, and
            /// create a custom implementation of a native UI action.
            ///
            self.newTabAction = { newTabButton.sendAction(
                newTabButton.action,
                to: newTabButton.target
            ) }
            ///
            /// Hide the original button, and drop its constraints so that
            /// the tabs fill the full width of the `NSTabBar`.
            ///
            newTabButton.isHidden = true;
            NSLayoutConstraint.deactivate(newTabButton.constraints);
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


