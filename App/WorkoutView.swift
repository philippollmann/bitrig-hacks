import SwiftUI

/// The camera tab: live pose tracking, rep counter and pace meter.
struct WorkoutView: View {
  var tracker: PoseTracker
  var camera: CameraManager

  /// The most recent milestone we threw a little party for.
  @State private var celebratedMilestone = 0
  @State private var showConfetti = false

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

        if showConfetti {
          ConfettiView()
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity)
        }
      }
    }
    .statusBarHidden()
    .onChange(of: tracker.count) { _, newValue in
      celebrateIfNeeded(newValue)
    }
  }

  // MARK: - Overlay

  private var overlayUI: some View {
    VStack(spacing: 14) {
      counter
      Spacer()
      pepTalk
        .padding(.bottom, 4)
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
    VStack(spacing: 12) {
      tempoBadge

      TimelineView(.periodic(from: .now, by: 0.2)) { _ in
        PaceMeter(pace: tracker.pace, tempo: tracker.tempo, exercise: tracker.exercise)
      }

      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text("\(tracker.count)")
          .font(.system(size: 92, weight: .black, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(
            LinearGradient(colors: [.white, tracker.tempo.color],
                           startPoint: .top, endPoint: .bottom))
          .contentTransition(.numericText(value: Double(tracker.count)))
          .scaleEffect(showConfetti ? 1.12 : 1)
          .animation(.bouncy, value: tracker.count)
          .animation(.bouncy, value: showConfetti)
        Text(tracker.exercise.repNoun)
          .font(.system(.title2, design: .rounded).weight(.heavy))
          .foregroundStyle(.white.opacity(0.7))
          .padding(.bottom, 14)
      }
    }
    .padding(.vertical, 18)
    .padding(.horizontal, 30)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .strokeBorder(tracker.tempo.color.opacity(0.55), lineWidth: 2)
        .animation(.smooth, value: tracker.tempo)
    )
    .sensoryFeedback(.increase, trigger: tracker.count)
    .sensoryFeedback(.success, trigger: celebratedMilestone)
  }

  /// A bouncy little badge showing the current effort with personality.
  private var tempoBadge: some View {
    HStack(spacing: 7) {
      Image(systemName: tracker.tempo.symbol)
        .symbolEffect(.bounce, value: tracker.count)
        .contentTransition(.symbolEffect(.replace))
      Text(tracker.tempo.label.uppercased())
        .font(.caption.weight(.heavy))
        .tracking(1.5)
    }
    .foregroundStyle(tracker.tempo.color)
    .padding(.horizontal, 14)
    .padding(.vertical, 7)
    .background(tracker.tempo.color.opacity(0.18), in: .capsule)
    .animation(.bouncy, value: tracker.tempo)
  }

  /// A rotating bit of encouragement that reacts to how hard you're working.
  private var pepTalk: some View {
    Text(tracker.tempo.pep(count: tracker.count))
      .font(.system(.headline, design: .rounded).weight(.bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 18)
      .padding(.vertical, 10)
      .glassEffect(in: .capsule)
      .contentTransition(.opacity)
      .animation(.smooth, value: tracker.tempo.pep(count: tracker.count))
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

  // MARK: - Celebrations

  /// Throw a quick confetti burst every 10 reps.
  private func celebrateIfNeeded(_ count: Int) {
    let milestone = (count / 10) * 10
    guard milestone >= 10, milestone != celebratedMilestone else { return }
    celebratedMilestone = milestone
    withAnimation(.snappy) { showConfetti = true }
    Task {
      try? await Task.sleep(for: .seconds(1.6))
      withAnimation(.smooth) { showConfetti = false }
    }
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
        Text("\(Int(pace.rounded())) / min")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(.white.opacity(0.85))
          .monospacedDigit()
        Spacer()
        Image(systemName: exercise.symbol)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(tempo.color)
          .symbolEffect(.bounce, options: .repeat(.continuous).speed(speed),
                        isActive: tempo != .idle)
      }

      GeometryReader { geo in
        let fraction = min(max(pace / exercise.meterMax, 0), 1)
        ZStack(alignment: .leading) {
          Capsule().fill(.white.opacity(0.18))
          Capsule()
            .fill(LinearGradient(
              colors: [.cyan, .mint, .orange, .pink],
              startPoint: .leading, endPoint: .trailing))
            .frame(width: max(geo.size.width * fraction, 8))
        }
      }
      .frame(height: 10)
      .animation(.smooth, value: pace)
    }
    .frame(width: 240)
  }

  /// The pace symbol bounces faster the harder you push.
  private var speed: Double {
    switch tempo {
    case .idle: 0.6
    case .slow: 1.0
    case .steady: 1.6
    case .fast: 2.4
    }
  }
}

/// A lightweight confetti burst that rains a handful of colorful pieces.
struct ConfettiView: View {
  private let pieces = (0..<36).map { _ in ConfettiPiece() }
  @State private var fall = false

  var body: some View {
    GeometryReader { geo in
      ZStack {
        ForEach(pieces) { piece in
          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(piece.color)
            .frame(width: 9, height: 13)
            .rotationEffect(.degrees(fall ? piece.spin : 0))
            .position(
              x: piece.x * geo.size.width,
              y: fall ? geo.size.height + 40 : -40)
            .opacity(fall ? 0 : 1)
            .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: fall)
        }
      }
    }
    .onAppear { fall = true }
  }
}

private struct ConfettiPiece: Identifiable {
  let id = UUID()
  let x = Double.random(in: 0.05...0.95)
  let spin = Double.random(in: 180...720)
  let duration = Double.random(in: 1.1...1.7)
  let delay = Double.random(in: 0...0.25)
  let color: Color = [.pink, .mint, .cyan, .orange, .yellow, .purple]
    .randomElement()!
}
