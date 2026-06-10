import SwiftUI

/// The pull-up sheet that replaces the tab bar. The now-playing bar stays
/// pinned on top; below it the user swipes between the workout controls and
/// the music settings pages.
struct WorkoutSheet: View {
  var tracker: PoseTracker
  var session: WorkoutSession
  var music: MusicController
  @Binding var showMusicSetup: Bool

  @State private var showNowPlaying = false

  var body: some View {
    VStack(spacing: 10) {
      MiniPlayerView(music: music) { showNowPlaying = true }
        .padding(.vertical, 8)
        .glassEffect(in: .capsule)
        .padding(.horizontal, 12)
        .padding(.top, 4)

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
