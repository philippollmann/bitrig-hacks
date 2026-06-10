import Foundation
import Observation
import AVFoundation
import FoundationModels

/// Generates short, spoken words of encouragement during a workout using the
/// on-device foundation model, and reads them aloud over the music.
@MainActor
@Observable
final class Coach {
  /// The most recent line the coach said, surfaced in the UI.
  private(set) var lastLine: String?

  /// Whether the on-device model is ready to use on this device.
  let isAvailable: Bool

  private let synthesizer = AVSpeechSynthesizer()
  private let session = LanguageModelSession(instructions: """
    You are an upbeat personal trainer cheering someone on during a live \
    workout. Reply with exactly ONE short spoken line of encouragement, no \
    more than 14 words. Be energetic, warm, and reference what they're doing \
    when it fits. Never use emoji, hashtags, quotation marks, or lists.
    """)

  private var lastCheer = Date.distantPast
  private var isGenerating = false

  /// Don't cheer more often than this, so the coach stays motivating not nagging.
  private let minInterval: TimeInterval = 25

  init() {
    isAvailable = SystemLanguageModel.default.isAvailable
    // Duck the music while speaking so the coaching is audible.
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
  }

  // MARK: - Triggers

  /// Kick off the workout with an opening cheer.
  func cheerStart(exercise: Exercise) {
    generate(prompt: """
      The workout is starting now. The exercise is \(exercise.rawValue). \
      Pump them up to begin.
      """, force: true)
  }

  /// Encourage mid-workout based on live progress. Throttled internally so it
  /// only speaks occasionally; call it freely (e.g. as the rep count climbs).
  func cheerProgress(exercise: Exercise, count: Int, pace: Double, tempo: Tempo, elapsed: TimeInterval) {
    let minutes = Int(elapsed) / 60
    let seconds = Int(elapsed) % 60
    generate(prompt: """
      They are doing \(exercise.rawValue) and have completed \(count) \
      \(exercise.repNoun) so far in \(minutes)m \(seconds)s. Their current pace \
      feels \(tempo.label.lowercased()) at about \(Int(pace.rounded())) per \
      minute. Cheer them on to keep going.
      """, force: false)
  }

  /// Celebrate the finished workout.
  func cheerFinish(exercise: Exercise, count: Int, elapsed: TimeInterval) {
    let minutes = Int(elapsed) / 60
    let seconds = Int(elapsed) % 60
    generate(prompt: """
      They just finished their workout: \(count) \(exercise.repNoun) of \
      \(exercise.rawValue) in \(minutes)m \(seconds)s. Congratulate them proudly.
      """, force: true)
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
  }

  // MARK: - Generation

  private func generate(prompt: String, force: Bool) {
    guard isAvailable, !isGenerating else { return }
    if !force, Date().timeIntervalSince(lastCheer) < minInterval { return }

    isGenerating = true
    lastCheer = Date()
    Task {
      defer { isGenerating = false }
      do {
        let response = try await session.respond(to: prompt)
        let line = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }
        lastLine = line
        speak(line)
      } catch {
        // A refusal or context error shouldn't interrupt the workout.
        print("Coach generation failed: \(error)")
      }
    }
  }

  private func speak(_ text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    synthesizer.speak(utterance)
  }
}
