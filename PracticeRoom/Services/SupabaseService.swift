//
//  SupabaseService.swift
//  PracticeRoom
//
//  Created by Thomas Walter on 10/6/25.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: Environment.supabaseURL,
    supabaseKey: Environment.supabaseKey
)

