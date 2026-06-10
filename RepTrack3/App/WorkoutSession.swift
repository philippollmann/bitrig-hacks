import Foundation
import Observation

/// Tracks an active workout: whether it's running and how long it has lasted.
@MainActor
@Observable
final class WorkoutSession {
  private(set) var isActive = false
  private var startDate: Date?
  private var accumulated: TimeInterval = 0

  /// Total elapsed time, live while the workout is running.
  var elapsed: TimeInterval {
    accumulated + (startDate.map { Date().timeIntervalSince($0) } ?? 0)
  }

  var formattedElapsed: String {
    let total = Int(elapsed)
    return String(format: "%02d:%02d", total / 60, total % 60)
  }

  func start() {
    guard !isActive else { return }
    startDate = Date()
    isActive = true
  }

  func stop() {
    guard isActive else { return }
    accumulated = elapsed
    startDate = nil
    isActive = false
  }

  func reset() {
    startDate = nil
    accumulated = 0
    isActive = false
  }
}
