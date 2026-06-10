import MusicKit
import SwiftUI

/// The expanded player: large artwork, glass transport controls and the
/// upcoming queue. Liquid Glass is used only on the floating controls that
/// sit above the blurred artwork backdrop.
struct NowPlayingView: View {
  var music: MusicController

  @ObservedObject private var state = ApplicationMusicPlayer.shared.state
  @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue
  @Environment(\.dismiss) private var dismiss

  private var isPlaying: Bool { state.playbackStatus == .playing }
  private var current: ApplicationMusicPlayer.Queue.Entry? { queue.currentEntry }

  var body: some View {
    ZStack {
      backdrop
      content
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - Background

  private var backdrop: some View {
    GeometryReader { geo in
      Group {
        if let artwork = current?.artwork {
          ArtworkImage(artwork, width: geo.size.width)
            .scaledToFill()
        } else {
          Color.black
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
      .clipped()
      .blur(radius: 50)
      .overlay(Color.black.opacity(0.45))
    }
    .ignoresSafeArea()
  }

  // MARK: - Foreground

  private var content: some View {
    VStack(spacing: 0) {
      Capsule()
        .fill(.white.opacity(0.5))
        .frame(width: 40, height: 5)
        .padding(.top, 10)

      heroArtwork
        .padding(.top, 28)

      VStack(spacing: 4) {
        Text(current?.title ?? "Not Playing")
          .font(.title2.weight(.bold))
          .lineLimit(1)
        if let subtitle = current?.subtitle {
          Text(subtitle)
            .font(.headline)
            .foregroundStyle(.white.opacity(0.75))
            .lineLimit(1)
        }
      }
      .multilineTextAlignment(.center)
      .padding(.horizontal, 32)
      .padding(.top, 22)

      transportControls
        .padding(.top, 24)

      upNext
        .padding(.top, 24)
    }
    .foregroundStyle(.white)
  }

  private var heroArtwork: some View {
    Group {
      if let artwork = current?.artwork {
        ArtworkImage(artwork, width: 260)
      } else {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(.white.opacity(0.12))
          .frame(width: 260, height: 260)
          .overlay(Image(systemName: "music.note").font(.system(size: 60)).foregroundStyle(.white.opacity(0.6)))
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
  }

  private var transportControls: some View {
    GlassEffectContainer {
      HStack(spacing: 36) {
        controlButton("backward.fill", size: 26) {
          await music.skipBackward()
        }
        controlButton(isPlaying ? "pause.fill" : "play.fill", size: 40) {
          await music.playPause()
        }
        controlButton("forward.fill", size: 26) {
          await music.skipForward()
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical, 18)
      .glassEffect(.regular.interactive(), in: .capsule)
    }
  }

  private func controlButton(_ symbol: String, size: CGFloat, action: @escaping () async -> Void) -> some View {
    Button {
      Task { await action() }
    } label: {
      Image(systemName: symbol)
        .font(.system(size: size, weight: .semibold))
        .frame(width: size + 14, height: size + 14)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(.white)
  }

  private var upNext: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Up Next")
        .font(.headline)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)

      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(queue.entries) { entry in
            queueRow(entry)
            if entry.id != queue.entries.last?.id {
              Divider().overlay(.white.opacity(0.15)).padding(.leading, 72)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  private func queueRow(_ entry: ApplicationMusicPlayer.Queue.Entry) -> some View {
    let isCurrent = entry.id == current?.id
    return HStack(spacing: 12) {
      Group {
        if let artwork = entry.artwork {
          ArtworkImage(artwork, width: 44)
        } else {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(.white.opacity(0.12))
            .frame(width: 44, height: 44)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        Text(entry.title)
          .font(.subheadline.weight(isCurrent ? .bold : .regular))
          .lineLimit(1)
        if let subtitle = entry.subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
            .lineLimit(1)
        }
      }
      Spacer()
      if isCurrent {
        Image(systemName: "speaker.wave.2.fill")
          .font(.caption)
          .foregroundStyle(.tint)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 24)
    .contentShape(Rectangle())
  }
}
