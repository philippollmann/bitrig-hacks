import SwiftUI

/// The pull-up sheet that replaces the tab bar. The now-playing bar stays
/// pinned on top; below it the user swipes between the workout controls and
/// the music settings pages.
struct WorkoutSheet: View {
  var tracker: PoseTracker
  var session: WorkoutSession
  var music: MusicController
  @Binding var showNowPlaying: Bool

  @State private var page = 0

  var body: some View {
    VStack(spacing: 0) {
      TabView(selection: $page) {
        WorkoutControlsView(tracker: tracker, session: session)
          .tag(0)
        MusicSetupView(music: music)
          .tag(1)
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
      .indexViewStyle(.page(backgroundDisplayMode: .interactive))
    }
    .sheet(isPresented: $showNowPlaying) {
      NowPlayingView(music: music)
    }
  }
}
