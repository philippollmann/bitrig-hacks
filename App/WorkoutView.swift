import SwiftUI

/// The camera tab: live pose tracking, rep counter and pace meter.
struct WorkoutView: View {
  var tracker: PoseTracker
  var camera: CameraManager
  var coach: Coach
  var session: WorkoutSession

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if tracker.cameraDenied {
        permissionDenied
      } else {
        CameraPreview(session: camera.session)
          .ignoresSafeArea()

        SkeletonOverlay(joints: tracker.joints, color: tracker.tempo.color)
          .ignoresSafeArea()

        overlayUI
      }
    }
    .statusBarHidden()
  }

  // MARK: - Overlay

  private var overlayUI: some View {
    VStack(spacing: 14) {
      counter
      if let line = coach.lastLine, session.isActive {
        coachLine(line)
      }
      Spacer()
      if !tracker.isTracking {
        coachingBanner
          .padding(.bottom, 8)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .environment(\.colorScheme, .dark)
  }

  private var counter: some View {
    VStack(spacing: 10) {
      TimelineView(.periodic(from: .now, by: 0.2)) { _ in
        PaceMeter(pace: tracker.pace, tempo: tracker.tempo, exercise: tracker.exercise)
      }

      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text("\(tracker.count)")
          .font(.system(size: 88, weight: .heavy, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText(value: Double(tracker.count)))
          .animation(.snappy, value: tracker.count)
        Text(tracker.exercise.repNoun)
          .font(.system(.title2, design: .rounded).weight(.semibold))
          .foregroundStyle(.white.opacity(0.7))
          .padding(.bottom, 12)
      }
      .foregroundStyle(.white)
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 28)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .sensoryFeedback(.increase, trigger: tracker.count)
  }

  private func coachLine(_ line: String) -> some View {
    Label(line, systemImage: "waveform")
      .font(.callout.weight(.semibold))
      .foregroundStyle(.white)
      .multilineTextAlignment(.leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .glassEffect(in: .capsule)
      .transition(.move(edge: .top).combined(with: .opacity))
      .animation(.snappy, value: line)
  }

  private var coachingBanner: some View {
    Label(tracker.exercise.coachingTip, systemImage: "viewfinder")
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .glassEffect(in: .capsule)
      .transition(.opacity.combined(with: .scale))
  }

  private var permissionDenied: some View {
    ContentUnavailableView {
      Label("Camera Access Needed", systemImage: "camera.fill")
    } description: {
      Text("RepTrack uses the front camera to track your movement. Enable camera access in Settings to start counting.")
    } actions: {
      Button("Open Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .foregroundStyle(.white)
  }
}

/// A horizontal meter showing the current pace and tempo label.
struct PaceMeter: View {
  var pace: Double
  var tempo: Tempo
  var exercise: Exercise

  var body: some View {
    VStack(spacing: 6) {
      HStack {
        Text(tempo.label)
          .font(.headline.weight(.bold))
          .foregroundStyle(tempo.color)
        Spacer()
        Text("\(Int(pace.rounded())) / min")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white.opacity(0.7))
          .monospacedDigit()
      }

      GeometryReader { geo in
        let fraction = min(max(pace / exercise.meterMax, 0), 1)
        ZStack(alignment: .leading) {
          Capsule().fill(.white.opacity(0.18))
          Capsule()
            .fill(LinearGradient(
              colors: [.cyan, .green, .orange],
              startPoint: .leading, endPoint: .trailing))
            .frame(width: geo.size.width * fraction)
        }
      }
      .frame(height: 8)
      .animation(.smooth, value: pace)
    }
    .frame(width: 240)
  }
}
