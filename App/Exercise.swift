import SwiftUI

/// The movements RepTrack knows how to count.
enum Exercise: String, CaseIterable, Identifiable {
  case jumpingJacks = "Jumping Jacks"
  case running = "Running"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .jumpingJacks: "figure.jumprope"
    case .running: "figure.run"
    }
  }

  /// A playful nickname shown when the workout is in full swing.
  var hypeName: String {
    switch self {
    case .jumpingJacks: "Jack Attack"
    case .running: "Knees Up!"
    }
  }

  /// What a single counted unit is called.
  var repNoun: String {
    switch self {
    case .jumpingJacks: "jacks"
    case .running: "steps"
    }
  }

  /// The signature color that themes the UI for this exercise.
  var accent: Color {
    switch self {
    case .jumpingJacks: .pink
    case .running: .mint
    }
  }

  /// Pace (reps per minute) below this counts as "Slow".
  var slowMax: Double {
    switch self {
    case .jumpingJacks: 25
    case .running: 55
    }
  }

  /// Pace at or above this counts as "Fast".
  var fastMin: Double {
    switch self {
    case .jumpingJacks: 45
    case .running: 115
    }
  }

  /// Full-scale value for the on-screen pace meter.
  var meterMax: Double {
    switch self {
    case .jumpingJacks: 70
    case .running: 170
    }
  }

  var coachingTip: String {
    switch self {
    case .jumpingJacks: "Stand back so your arms and legs stay in frame, then jump!"
    case .running: "Step back a bit and run in place — lift those knees!"
    }
  }
}

/// A qualitative description of how fast the user is moving.
enum Tempo {
  case idle, slow, steady, fast

  /// A peppy, personality-filled status label.
  var label: String {
    switch self {
    case .idle: "Ready?"
    case .slow: "Warming Up"
    case .steady: "In the Zone"
    case .fast: "On Fire!"
    }
  }

  /// An expressive symbol that captures the vibe.
  var symbol: String {
    switch self {
    case .idle: "sparkles"
    case .slow: "tortoise.fill"
    case .steady: "hare.fill"
    case .fast: "flame.fill"
    }
  }

  var color: Color {
    switch self {
    case .idle: .gray
    case .slow: .cyan
    case .steady: .orange
    case .fast: .pink
    }
  }

  /// A short cheer that matches the current effort.
  func pep(count: Int) -> String {
    switch self {
    case .idle:
      return count == 0 ? "Let's gooo!" : "Catch your breath…"
    case .slow:
      return "Nice and easy"
    case .steady:
      return "Looking strong!"
    case .fast:
      return "You're crushing it!"
    }
  }
}
