import SwiftUI
import Vision

/// Draws the tracked body skeleton over the camera feed.
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
    Canvas { context, size in
      func map(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
      }

      for (a, b) in Self.bones {
        guard let pa = joints[a], let pb = joints[b] else { continue }
        var path = Path()
        path.move(to: map(pa))
        path.addLine(to: map(pb))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 5, lineCap: .round))
      }

      for point in joints.values {
        let center = map(point)
        let dot = Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
        context.fill(dot, with: .color(.white))
      }
    }
    .allowsHitTesting(false)
  }
}
