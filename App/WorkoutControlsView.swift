import SwiftUI

/// The workout page of the pull-up sheet: start/stop, live time, pace and reps.
struct WorkoutControlsView: View {
  @Bindable var tracker: PoseTracker
  @Bindable var session: WorkoutSession

  var body: some View {
    ScrollView {
      VStack(spacing: 18) {
        header

        // Live stats — refreshed continuously while the workout runs.
        TimelineView(.periodic(from: .now, by: 0.3)) { _ in
          HStack(spacing: 0) {
            stat(label: "TIME", value: session.formattedElapsed, tint: .primary)
            divider
            stat(label: tracker.exercise.repNoun.uppercased(), value: "\(tracker.count)", tint: tracker.exercise.accent)
            divider
            stat(label: paceLabel, value: "\(Int(tracker.pace.rounded()))", tint: tracker.tempo.color)
          }
          .padding(.vertical, 14)
          .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        startStopButton

        Picker("Exercise", selection: $tracker.exercise) {
          ForEach(Exercise.allCases) { exercise in
            Label(exercise.rawValue, systemImage: exercise.symbol).tag(exercise)
          }
        }
        .pickerStyle(.segmented)
        .disabled(session.isActive)

        Button {
          withAnimation(.bouncy) { tracker.reset() }
        } label: {
          Label("Start Over", systemImage: "arrow.counterclockwise")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
        .tint(.secondary)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 8)
    }
    .scrollBounceBehavior(.basedOnSize)
    // Keep content clear of the floating page-indicator dots and sheet edge.
    .contentMargins(.bottom, 44, for: .scrollContent)
  }

  private var paceLabel: String {
    tracker.exercise == .running ? "PACE/MIN" : "TEMPO/MIN"
  }

  // MARK: - Pieces

  /// A peppy title that shows the workout's vibe.
  private var header: some View {
    HStack(spacing: 10) {
      Image(systemName: tracker.exercise.symbol)
        .font(.title2.weight(.bold))
        .foregroundStyle(tracker.exercise.accent)
        .symbolEffect(.bounce, value: session.isActive)
      Text(session.isActive ? tracker.exercise.hypeName : "Ready to Move?")
        .font(.system(.title2, design: .rounded).weight(.heavy))
        .contentTransition(.opacity)
      Spacer()
    }
    .animation(.bouncy, value: session.isActive)
  }

  private var startStopButton: some View {
    Button {
      withAnimation(.bouncy) { toggle() }
    } label: {
      HStack(spacing: 12) {
        Image(systemName: session.isActive ? "stop.fill" : "play.fill")
          .font(.title3)
          .symbolEffect(.bounce, value: session.isActive)
        Text(session.isActive ? "Finish Up" : "Let's Move!")
          .font(.system(.headline, design: .rounded).weight(.heavy))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 17)
      .background(
        (session.isActive ? AnyShapeStyle(Color.red.gradient)
                          : AnyShapeStyle(tracker.exercise.accent.gradient)),
        in: Capsule())
      .shadow(color: (session.isActive ? .red : tracker.exercise.accent).opacity(0.5),
              radius: 12, y: 4)
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.impact(weight: .medium), trigger: session.isActive)
  }

  private func stat(label: String, value: String, tint: Color) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 30, weight: .heavy, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(tint)
        .contentTransition(.numericText())
      Text(label)
        .font(.caption2.weight(.bold))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }

  private var divider: some View {
    Rectangle()
      .fill(.quaternary)
      .frame(width: 1, height: 30)
  }

  private func toggle() {
    if session.isActive {
      session.stop()
      tracker.isCounting = false
    } else {
      tracker.reset()
      session.start()
      tracker.isCounting = true
    }
  }
}
