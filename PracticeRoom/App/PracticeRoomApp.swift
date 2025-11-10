//
//  PracticeRoomApp.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/3/25.
//

import SwiftUI

@main
struct PracticeRoomApp: App {
    init() {
        // Configure segmented control (Picker) font
        let segmentedControlAppearance = UISegmentedControl.appearance()
        segmentedControlAppearance.setTitleTextAttributes([
            .font: UIFont(name: "Merriweather-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        ], for: .normal)
        segmentedControlAppearance.setTitleTextAttributes([
            .font: UIFont(name: "Merriweather-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        ], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}
