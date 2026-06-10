import MusicKit
import SwiftUI

/// A list of the user's library playlists for choosing one intensity source.
struct PlaylistPickerView: View {
  let playlists: [Playlist]
  @Binding var selection: Playlist?
  let title: String

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List(playlists) { playlist in
      Button {
        selection = playlist
        dismiss()
      } label: {
        HStack(spacing: 12) {
          artwork(for: playlist)
          Text(playlist.name)
            .foregroundStyle(.primary)
            .lineLimit(1)
          Spacer()
          if selection?.id == playlist.id {
            Image(systemName: "checkmark")
              .foregroundStyle(.tint)
              .fontWeight(.semibold)
          }
        }
      }
    }
    .navigationTitle("\(title) Playlist")
    .navigationBarTitleDisplayMode(.inline)
    .overlay {
      if playlists.isEmpty {
        ContentUnavailableView("No Playlists",
                               systemImage: "music.note.list",
                               description: Text("Create a playlist in Apple Music to use it here."))
      }
    }
  }

  @ViewBuilder
  private func artwork(for playlist: Playlist) -> some View {
    if let artwork = playlist.artwork {
      ArtworkImage(artwork, width: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    } else {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(.quaternary)
        .frame(width: 48, height: 48)
        .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
    }
  }
}
