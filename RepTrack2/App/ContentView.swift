import SwiftUI

struct ContentView: View {
  @State private var tracker = PoseTracker()
  @State private var camera = CameraManager()
  @State private var music = MusicController()
  @State private var showNowPlaying = false

  var body: some View {
    TabView {
      Tab("Train", systemImage: "figure.run") {
        WorkoutView(tracker: tracker, camera: camera)
      }
      Tab("Music", systemImage: "music.note.list") {
        MusicSetupView(music: music)
      }
    }
    .tabViewBottomAccessory {
      MiniPlayerView(music: music) { showNowPlaying = true }
    }
    .sheet(isPresented: $showNowPlaying) {
      NowPlayingView(music: music)
    }
    // The detected workout intensity drives what gets queued.
    .onChange(of: tracker.tempo) { _, newValue in
      music.handleEnergy(newValue)
    }
    .task {
      camera.tracker = tracker
      camera.start()
    }
    .task {
      await music.requestAuthorization()
    }
  }
}
