//
//  AppView.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import SwiftUI
internal import Auth
import Supabase

struct AppView: View {                  // View: defines a visual element of screen. Can be made up of other views
  @State var isAuthenticated = false

  var body: some View {
    Group {
      if isAuthenticated {
        ProfileView()
      } else {
        AuthView()
      }
    }
    .task {
      for await state in supabase.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
          isAuthenticated = state.session != nil
        }
      }
    }
  }
}
