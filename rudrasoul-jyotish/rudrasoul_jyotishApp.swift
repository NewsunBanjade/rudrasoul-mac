//
//  rudrasoul_jyotishApp.swift
//  rudrasoul-jyotish
//
//  Created by Newsun on 9/17/26.
//

import AppKit
import SwiftUI

@main
struct rudrasoul_jyotishApp: App {
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    /// The single workspace: library plus the open chart tabs. Owned here so that the menu
    /// commands and the window share one model.
    @State private var model = ChartScreenModel()

    var body: some Scene {
        Window("Jyotish Pro", id: "main") {
            ContentView(model: model)
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Chart…") {
                    model.isPresentingNewChart = true
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button("Show Library") {
                    model.showLibrary()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Close Tab") {
                    model.closeSelectedTab()
                }
                .keyboardShortcut("w", modifiers: [.command])

                Button("Close Window") {
                    NSApp.keyWindow?.performClose(nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }

            CommandGroup(after: .sidebar) {
                Divider()
                Button("Next Tab") {
                    model.selectAdjacentTab(offset: 1)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Previous Tab") {
                    model.selectAdjacentTab(offset: -1)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Divider()
                Button("Recalculate Chart") {
                    model.recalculateActiveChart()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsScreen()
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: \.isVisible) ?? NSApp.windows.first else {
                return
            }

            let availableFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? window.frame
            window.setFrame(availableFrame, display: true)
        }
    }
}
