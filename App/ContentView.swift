import SwiftUI
import UIKit

struct ContentView: View {
  @State private var tracker = PoseTracker()
  @State private var camera = CameraManager()
  @State private var music = MusicController()
  @State private var session = WorkoutSession()
  @State private var sheetPresented = true

  /// Collapsed height of the pull-up sheet; the camera stays interactive above it.
  private let collapsedHeight: CGFloat = 300

  var body: some View {
    WorkoutView(tracker: tracker, camera: camera)
      .sheet(isPresented: $sheetPresented) {
        WorkoutSheet(tracker: tracker, session: session, music: music)
          .presentationDetents([.height(collapsedHeight), .large])
          .presentationBackgroundInteraction(.enabled(upThrough: .height(collapsedHeight)))
          .presentationDragIndicator(.visible)
          .presentationBackground(.regularMaterial)
          .interactiveDismissDisabled()
      }
      // Workout intensity adapts the music, but only during an active workout.
      .onChange(of: tracker.tempo) { _, newValue in
        if session.isActive { music.handleEnergy(newValue) }
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
