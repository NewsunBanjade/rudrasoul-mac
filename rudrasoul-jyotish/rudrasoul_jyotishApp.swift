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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
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
