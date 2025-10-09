//
//  PracticeRoomApp.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/3/25.
//

import SwiftUI

@main                               // identifies entry point, can only be applied to one structure
struct PracticeRoomApp: App {       // conforms to the App protocol
    var body: some Scene {          // body conforms to the content of a Scene - contains the view hierarchy
        WindowGroup {               // provides platform specific behaviors
            AppView()
        }
    }
}
