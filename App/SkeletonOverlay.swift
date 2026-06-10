import SwiftUI
import Vision

/// Draws the tracked body skeleton over the camera feed with a playful neon glow.
struct SkeletonOverlay: View {
  var joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
  var color: Color

  /// Bones to connect, as pairs of joint names.
  private static let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
    (.neck, .nose),
    (.leftShoulder, .rightShoulder),
    (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
    (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
    (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
    (.leftHip, .rightHip),
    (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
    (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
  ]

  var body: some View {
    // A gentle pulse keeps the skeleton feeling alive.
    TimelineView(.animation) { timeline in
      let t = timeline.date.timeIntervalSinceReferenceDate
      let pulse = 0.5 + 0.5 * sin(t * 3)

      Canvas { context, size in
        func map(_ p: CGPoint) -> CGPoint {
          CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
        }

        // Glow pass: a wide, soft stroke under the crisp bones.
        for (a, b) in Self.bones {
          guard let pa = joints[a], let pb = joints[b] else { continue }
          var path = Path()
          path.move(to: map(pa))
          path.addLine(to: map(pb))
          context.stroke(path, with: .color(color.opacity(0.35)),
                         style: StrokeStyle(lineWidth: 14, lineCap: .round))
        }

        for (a, b) in Self.bones {
          guard let pa = joints[a], let pb = joints[b] else { continue }
          var path = Path()
          path.move(to: map(pa))
          path.addLine(to: map(pb))
          context.stroke(path, with: .color(color),
                         style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }

        for point in joints.values {
          let center = map(point)
          let r = 6 + 2 * pulse
          let halo = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
          context.fill(halo, with: .color(color.opacity(0.6)))
          let dot = Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
          context.fill(dot, with: .color(.white))
        }
      }
    }
    .allowsHitTesting(false)
  }
}
