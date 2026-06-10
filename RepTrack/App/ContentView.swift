import SwiftUI

struct ContentView: View {
  @State private var tracker = PoseTracker()
  @State private var camera = CameraManager()

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
    .onAppear {
      camera.tracker = tracker
      camera.start()
    }
    .onDisappear { camera.stop() }
    .statusBarHidden()
  }

  // MARK: - Overlay

  private var overlayUI: some View {
    VStack(spacing: 0) {
      counter
        .padding(.top, 8)

      Spacer()

      if !tracker.isTracking {
        coachingBanner
          .padding(.bottom, 12)
      }

      controls
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 24)
  }

  private var counter: some View {
    VStack(spacing: 10) {
      // Live pace, refreshed continuously so it decays when the user pauses.
      TimelineView(.periodic(from: .now, by: 0.2)) { _ in
        PaceMeter(pace: tracker.pace, tempo: tracker.tempo, exercise: tracker.exercise)
      }

      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text("\(tracker.count)")
          .font(.system(size: 96, weight: .heavy, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText(value: Double(tracker.count)))
          .animation(.snappy, value: tracker.count)
        Text(tracker.exercise.repNoun)
          .font(.system(.title2, design: .rounded).weight(.semibold))
          .foregroundStyle(.white.opacity(0.7))
          .padding(.bottom, 14)
      }
      .foregroundStyle(.white)
    }
    .padding(.vertical, 18)
    .padding(.horizontal, 28)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .environment(\.colorScheme, .dark)
  }

  private var coachingBanner: some View {
    Label(tracker.exercise.coachingTip, systemImage: "viewfinder")
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial, in: Capsule())
      .environment(\.colorScheme, .dark)
      .transition(.opacity.combined(with: .scale))
  }

  private var controls: some View {
    HStack(spacing: 12) {
      Picker("Exercise", selection: $tracker.exercise) {
        ForEach(Exercise.allCases) { exercise in
          Label(exercise.rawValue, systemImage: exercise.symbol).tag(exercise)
        }
      }
      .pickerStyle(.segmented)

      Button {
        withAnimation(.snappy) { tracker.reset() }
      } label: {
        Image(systemName: "arrow.counterclockwise")
          .font(.headline)
          .frame(width: 44, height: 44)
          .background(.ultraThinMaterial, in: Circle())
      }
      .tint(.white)
      .accessibilityLabel("Reset count")
    }
    .environment(\.colorScheme, .dark)
    .sensoryFeedback(.increase, trigger: tracker.count)
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
private struct PaceMeter: View {
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
