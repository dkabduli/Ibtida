//
//  LoadState.swift
//  Ibtida
//
//  Shared loading state for list/feed screens. Use to avoid blank-first-tap and ad-hoc isLoading/errorMessage.
//  BEHAVIOR LOCK: Same UI outcomes (loading placeholder, empty, error); only internal state shape changes.
//

import Foundation

/// Consistent load state for screens that fetch a list or single resource.
/// Prefer this over separate isLoading + errorMessage to avoid blanks and double-fetch.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
    
    /// Show loading placeholder when loading and no data yet
    static func showLoadingPlaceholder(loadState: LoadState, isEmpty: Bool) -> Bool {
        loadState == .loading && isEmpty
    }
}
