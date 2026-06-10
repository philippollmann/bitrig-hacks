import MusicKit
import SwiftUI

/// The music tab: authorize Apple Music, choose the chill and energy
/// playlists, and toggle how aggressively the music adapts.
struct MusicSetupView: View {
  @Bindable var music: MusicController

  var body: some View {
    NavigationStack {
      Group {
        switch music.authState {
        case .unknown:
          ProgressView("Connecting to Apple Music…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .denied:
          deniedView
        case .authorized:
          settingsList
        }
      }
      .navigationTitle("Adaptive Music")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var settingsList: some View {
    List {
      Section {
        playlistRow(
          title: "Chill",
          subtitle: "Played when you ease off",
          symbol: "leaf.fill",
          tint: .cyan,
          selection: music.chillPlaylist,
          binding: $music.chillPlaylist)
        playlistRow(
          title: "Energy",
          subtitle: "Played when you push hard",
          symbol: "bolt.fill",
          tint: .orange,
          selection: music.energyPlaylist,
          binding: $music.energyPlaylist)
      } header: {
        Text("Playlists")
      } footer: {
        Text("Pick a playlist from your library for each intensity. RepTrack watches how fast you're moving and matches the music.")
      }

      Section {
        Toggle(isOn: $music.autoSkip) {
          Label("Skip on energy change", systemImage: "forward.fill")
        }
      } footer: {
        Text(music.autoSkip
             ? "Changing intensity skips straight to a matching song."
             : "Matching songs are added to the queue and play after the current track. Turn on to skip immediately instead.")
      }

      if !music.isReady {
        Section {
          Label("Choose both playlists to start adapting your workout music.",
                systemImage: "info.circle.fill")
            .foregroundStyle(.secondary)
            .font(.subheadline)
        }
      }
    }
  }

  private func playlistRow(
    title: String,
    subtitle: String,
    symbol: String,
    tint: Color,
    selection: Playlist?,
    binding: Binding<Playlist?>
  ) -> some View {
    NavigationLink {
      PlaylistPickerView(playlists: music.libraryPlaylists, selection: binding, title: title)
    } label: {
      HStack(spacing: 14) {
        Image(systemName: symbol)
          .font(.headline)
          .foregroundStyle(.white)
          .frame(width: 38, height: 38)
          .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(.headline)
          Text(selection?.name ?? subtitle)
            .font(.subheadline)
            .foregroundStyle(selection == nil ? .secondary : .primary)
            .lineLimit(1)
        }
      }
    }
  }

  private var deniedView: some View {
    ContentUnavailableView {
      Label("Apple Music Not Available", systemImage: "music.note.list")
    } description: {
      Text("RepTrack needs access to Apple Music to play and adapt your playlists. Enable it in Settings, and make sure you have an active Apple Music subscription.")
    } actions: {
      Button("Open Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      .buttonStyle(.borderedProminent)
    }
  }
}
