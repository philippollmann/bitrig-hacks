import SwiftUI

/// The pull-up sheet that replaces the tab bar. The now-playing bar stays
/// pinned on top with the workout controls below; adaptive-music settings open
/// from a toolbar button.
struct WorkoutSheet: View {
  var tracker: PoseTracker
  var session: WorkoutSession
  var music: MusicController
  @Binding var showMusicSetup: Bool

  @State private var showNowPlaying = false
  @State private var showMusicSetup = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 10) {
        MiniPlayerView(music: music) { showNowPlaying = true }
          .padding(.vertical, 8)
          .glassEffect(in: .capsule)
          .padding(.horizontal, 12)

      WorkoutControlsView(tracker: tracker, session: session)
    }
    .sheet(isPresented: $showNowPlaying) {
      NowPlayingView(music: music)
    }
    .sheet(isPresented: $showMusicSetup) {
      MusicSetupView(music: music)
    }
  }
}
