import Foundation

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    static let `default` = RetryPolicy(maxAttempts: 10, baseDelay: 1, maxDelay: 60)

    func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2, Double(attempt))
        let capped = min(exponential, maxDelay)
        let jitter = Double.random(in: 0...(capped * 0.25))
        return capped + jitter
    }

    func shouldRetry(attempt: Int) -> Bool {
        attempt < maxAttempts
    }
}
