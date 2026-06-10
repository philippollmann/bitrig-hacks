import Foundation
import QuartzCore
import Vision

/// Owns the rep count, the live pace, and the latest body joints.
///
/// Joint positions are stored in Vision's normalized space (origin bottom-left,
/// y pointing up, values 0…1) already oriented to match the mirrored front-camera
/// preview, so views map them with `x * width`, `(1 - y) * height`.
@Observable
final class PoseTracker {
  /// The exercise currently being counted.
  var exercise: Exercise = .jumpingJacks {
    didSet { if exercise != oldValue { reset() } }
  }

  /// Completed reps for the current session.
  private(set) var count = 0

  /// Latest confident joints, keyed by Vision joint name.
  private(set) var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

  /// Whether a body is currently being tracked.
  private(set) var isTracking = false

  /// Set when camera access was denied.
  var cameraDenied = false

  // Timestamps (CACurrentMediaTime) of recent reps, used to derive pace.
  private var repTimes: [TimeInterval] = []

  // Movement state machines.
  private var armsOpen = false
  private var leftLegUp = false
  private var rightLegUp = false

  // MARK: - Frame input

  /// Replace the tracked joints and advance the rep detector.
  func update(_ joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
    self.joints = joints
    isTracking = !joints.isEmpty
    guard isTracking else { return }
    switch exercise {
    case .jumpingJacks: detectJumpingJack()
    case .running: detectRunningStep()
    }
  }

  /// Clear tracking when no body is in frame.
  func clear() {
    joints = [:]
    isTracking = false
  }

  func reset() {
    count = 0
    repTimes.removeAll()
    armsOpen = false
    leftLegUp = false
    rightLegUp = false
  }

  // MARK: - Pace

  /// Reps per minute over the recent window, decaying toward zero when idle.
  var pace: Double {
    let now = CACurrentMediaTime()
    let recent = repTimes.filter { now - $0 < 6 }
    guard recent.count >= 2, let first = recent.first else { return 0 }
    let span = max(now - first, 0.001)
    return Double(recent.count) / span * 60
  }

  var tempo: Tempo {
    let p = pace
    if p < 1 { return .idle }
    if p < exercise.slowMax { return .slow }
    if p < exercise.fastMin { return .steady }
    return .fast
  }

  private func registerRep() {
    count += 1
    repTimes.append(CACurrentMediaTime())
    if repTimes.count > 12 { repTimes.removeFirst(repTimes.count - 12) }
  }

  // MARK: - Detectors

  private func detectJumpingJack() {
    guard let lw = joints[.leftWrist], let rw = joints[.rightWrist],
          let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] else { return }
    let wristY = (lw.y + rw.y) / 2
    let shoulderY = (ls.y + rs.y) / 2
    // Arms up: wrists above the shoulders. Hysteresis avoids double counting.
    if !armsOpen, wristY > shoulderY + 0.03 {
      armsOpen = true
      registerRep()
    } else if armsOpen, wristY < shoulderY - 0.08 {
      armsOpen = false
    }
  }

  private func detectRunningStep() {
    guard let ls = joints[.leftShoulder], let rs = joints[.rightShoulder],
          let lh = joints[.leftHip], let rh = joints[.rightHip] else { return }
    let shoulderY = (ls.y + rs.y) / 2
    let hipY = (lh.y + rh.y) / 2
    let torso = abs(shoulderY - hipY)
    guard torso > 0.05 else { return }

    leftLegUp = step(hip: lh, knee: joints[.leftKnee], torso: torso, wasUp: leftLegUp)
    rightLegUp = step(hip: rh, knee: joints[.rightKnee], torso: torso, wasUp: rightLegUp)
  }

  /// Returns the new "leg raised" state, counting a step on the rising edge.
  /// `ratio` is the knee's drop below the hip, normalized by torso length, so it
  /// is scale-invariant regardless of how far the user stands from the camera.
  private func step(hip: CGPoint, knee: CGPoint?, torso: Double, wasUp: Bool) -> Bool {
    guard let knee else { return wasUp }
    let ratio = (hip.y - knee.y) / torso
    if !wasUp, ratio < 0.55 {
      registerRep()
      return true
    } else if wasUp, ratio > 0.8 {
      return false
    }
    return wasUp
  }
}
