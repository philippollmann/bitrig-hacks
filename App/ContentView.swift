import SwiftUI
import UIKit

struct ContentView: View {
  @State private var tracker = PoseTracker()
  @State private var camera = CameraManager()
  @State private var music = MusicController()
  @State private var session = WorkoutSession()
  @State private var coach = Coach()
  @State private var sheetPresented = true
  @State private var showMusicSetup = false

  /// Collapsed height of the pull-up sheet; the camera stays interactive above it.
  private let collapsedHeight: CGFloat = 300

  var body: some View {
    NavigationStack {
      WorkoutView(tracker: tracker, camera: camera, coach: coach, session: session)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              showMusicSetup = true
            } label: {
              Label("Music Setup", systemImage: "music.note.list")
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
          }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
      }
      .sheet(isPresented: $sheetPresented) {
        WorkoutSheet(tracker: tracker, session: session, music: music, showMusicSetup: $showMusicSetup)
          .presentationDetents([.height(collapsedHeight), .large])
          .presentationBackgroundInteraction(.enabled(upThrough: .height(collapsedHeight)))
          .presentationDragIndicator(.visible)
          .presentationBackground {
            Color.clear.glassEffect(in: .rect)
          }
          .interactiveDismissDisabled()
      }
      // Workout intensity adapts the music, but only during an active workout.
      .onChange(of: tracker.tempo) { _, newValue in
        if session.isActive { music.handleEnergy(newValue) }
      }
      // The on-device coach cheers the user on as they start, work, and finish.
      .onChange(of: session.isActive) { _, active in
        if active {
          coach.cheerStart(exercise: tracker.exercise)
        } else {
          coach.cheerFinish(exercise: tracker.exercise, count: tracker.count, elapsed: session.elapsed)
        }
      }
      .onChange(of: tracker.count) { _, _ in
        guard session.isActive else { return }
        coach.cheerProgress(exercise: tracker.exercise, count: tracker.count,
                            pace: tracker.pace, tempo: tracker.tempo, elapsed: session.elapsed)
      }
      // Keep the screen awake while training.
      .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
      .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
      .task {
        camera.tracker = tracker
        camera.start()
      }
      .task {
        await music.requestAuthorization()
      }
  }
}
