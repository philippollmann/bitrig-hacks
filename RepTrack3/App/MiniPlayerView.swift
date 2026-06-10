import MusicKit
import SwiftUI

/// The compact now-playing bar shown in the tab view's glass bottom accessory.
/// Tapping the song info expands the full Now Playing sheet.
struct MiniPlayerView: View {
  var music: MusicController
  var onExpand: () -> Void

  @ObservedObject private var state = ApplicationMusicPlayer.shared.state
  @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue

  private var isPlaying: Bool { state.playbackStatus == .playing }

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onExpand) {
        HStack(spacing: 10) {
          artwork
          VStack(alignment: .leading, spacing: 1) {
            Text(queue.currentEntry?.title ?? "Not Playing")
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
            if let subtitle = queue.currentEntry?.subtitle, !subtitle.isEmpty {
              Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Button {
        Task { await music.playPause() }
      } label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.title3)
          .frame(width: 30, height: 30)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isPlaying ? "Pause" : "Play")

      Button {
        Task { await music.skipForward() }
      } label: {
        Image(systemName: "forward.fill")
          .font(.title3)
          .frame(width: 30, height: 30)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Next")
    }
    .padding(.horizontal, 12)
    .tint(.primary)
  }

  @ViewBuilder private var artwork: some View {
    if let artwork = queue.currentEntry?.artwork {
      ArtworkImage(artwork, width: 34)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    } else {
      RoundedRectangle(cornerRadius: 7, style: .continuous)
        .fill(.quaternary)
        .frame(width: 34, height: 34)
        .overlay(Image(systemName: "music.note").font(.caption).foregroundStyle(.secondary))
    }
  }
}
