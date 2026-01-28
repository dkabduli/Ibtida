//
//  NetworkErrorHandler.swift
//  Ibtida
//
//  Centralized network error handling with retry logic
//

import Foundation
import FirebaseFirestore

/// Centralized network error detection and handling
enum NetworkErrorHandler {
    
    // MARK: - Error Detection
    
    /// Check if error is a network connectivity issue
    static func isNetworkError(_ error: Error) -> Bool {
        // Check Firestore UNAVAILABLE error
        if let nsError = error as NSError? {
            if nsError.domain == "FIRFirestoreErrorDomain" {
                return nsError.code == 14 // UNAVAILABLE
            }
            
            // Check URLError network issues
            if nsError.domain == NSURLErrorDomain {
                return nsError.code == NSURLErrorNotConnectedToInternet ||
                       nsError.code == NSURLErrorNetworkConnectionLost ||
                       nsError.code == NSURLErrorTimedOut ||
                       nsError.code == NSURLErrorCannotConnectToHost
            }
        }
        
        return false
    }
    
    /// Check if error is a timeout
    static func isTimeoutError(_ error: Error) -> Bool {
        if let nsError = error as NSError? {
            if nsError.domain == "FIRFirestoreErrorDomain" {
                return nsError.code == 4 // DEADLINE_EXCEEDED
            }
            if nsError.domain == NSURLErrorDomain {
                return nsError.code == NSURLErrorTimedOut
            }
        }
        return false
    }
    
    // MARK: - User-Friendly Messages
    
    /// Get user-friendly error message
    static func userFriendlyMessage(for error: Error) -> String {
        if isNetworkError(error) {
            return "No internet connection. Retrying..."
        } else if isTimeoutError(error) {
            return "Request timed out. Please try again."
        } else if let nsError = error as NSError? {
            if nsError.domain == "FIRFirestoreErrorDomain" {
                switch nsError.code {
                case 4: // DEADLINE_EXCEEDED
                    return "Request timed out. Please try again."
                case 7: // PERMISSION_DENIED
                    return "Permission denied. Please check your account."
                case 14: // UNAVAILABLE
                    return "No internet connection. Retrying..."
                default:
                    return "Unable to connect. Please try again."
                }
            }
        }
        return "Something went wrong. Please try again."
    }
    
    // MARK: - Retry Logic
    
    /// Retry an async operation with exponential backoff
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - initialDelay: Initial delay in seconds (default: 1.0)
    ///   - maxDelay: Maximum delay in seconds (default: 10.0)
    ///   - onRetry: Optional callback when retry starts (for UI updates)
    ///   - operation: The async operation to retry
    /// - Returns: Result of the operation or error after all retries
    static func retryWithBackoff<T>(
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 10.0,
        onRetry: ((Int) -> Void)? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Only retry network errors
                guard isNetworkError(error) || isTimeoutError(error) else {
                    throw error // Don't retry non-network errors
                }
                
                // Don't retry on last attempt
                guard attempt < maxRetries else {
                    break
                }
                
                // Notify retry callback
                onRetry?(attempt + 1)
                
                // Exponential backoff with jitter
                let jitter = Double.random(in: 0.0...0.3) * delay
                let backoffDelay = min(delay + jitter, maxDelay)
                
                AppLog.network("Retry attempt \(attempt + 1)/\(maxRetries) after \(String(format: "%.1f", backoffDelay))s")
                
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                delay *= 2.0 // Exponential backoff
            }
        }
        
        // All retries failed
        throw lastError ?? NSError(domain: "NetworkErrorHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
}
