import SwiftUI

/// The workout page of the pull-up sheet: start/stop, live time, pace and reps.
struct WorkoutControlsView: View {
  @Bindable var tracker: PoseTracker
  @Bindable var session: WorkoutSession

  var body: some View {
    ScrollView {
      VStack(spacing: 18) {
        // Live stats — refreshed continuously while the workout runs.
        TimelineView(.periodic(from: .now, by: 0.3)) { _ in
          HStack(spacing: 0) {
            stat(label: "TIME", value: session.formattedElapsed, tint: .primary)
            divider
            stat(label: tracker.exercise.repNoun.uppercased(), value: "\(tracker.count)", tint: .primary)
            divider
            stat(label: paceLabel, value: "\(Int(tracker.pace.rounded()))", tint: tracker.tempo.color)
          }
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
          tracker.reset()
        } label: {
          Label("Reset Reps", systemImage: "arrow.counterclockwise")
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

  private var startStopButton: some View {
    Button {
      withAnimation(.snappy) { toggle() }
    } label: {
      HStack(spacing: 12) {
        Image(systemName: session.isActive ? "stop.fill" : "play.fill")
          .font(.title3)
        Text(session.isActive ? "End Workout" : "Start Workout")
          .font(.headline)
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background((session.isActive ? Color.red : Color.green).gradient,
                  in: Capsule())
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.impact(weight: .medium), trigger: session.isActive)
  }

  private func stat(label: String, value: String, tint: Color) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 30, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(tint)
      Text(label)
        .font(.caption2.weight(.semibold))
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
