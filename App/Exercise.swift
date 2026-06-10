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

  /// What a single counted unit is called.
  var repNoun: String {
    switch self {
    case .jumpingJacks: "jacks"
    case .running: "steps"
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
    case .jumpingJacks: "Stand back so your arms and legs stay in frame, then jump."
    case .running: "Step back a bit and run in place — lift those knees."
    }
  }
}

/// A qualitative description of how fast the user is moving.
enum Tempo {
  case idle, slow, steady, fast

  var label: String {
    switch self {
    case .idle: "Ready"
    case .slow: "Slow"
    case .steady: "Steady"
    case .fast: "Fast"
    }
  }

  var color: Color {
    switch self {
    case .idle: .gray
    case .slow: .cyan
    case .steady: .orange
    case .fast: .green
    }
  }
}
