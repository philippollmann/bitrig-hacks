import Foundation
import MusicKit
import Observation

/// How hard the user is currently working, derived from the pose tempo.
enum EnergyLevel {
  case low, high
}

/// Bridges the workout's detected energy to Apple Music playback: holds the
/// chosen chill / energy playlists and adapts the queue as intensity changes.
@MainActor
@Observable
final class MusicController {
  enum AuthState {
    case unknown, authorized, denied
  }

  var authState: AuthState = .unknown

  /// Playlists from the user's library, offered for selection.
  var libraryPlaylists: [Playlist] = []
  var isLoadingLibrary = false

  var chillPlaylist: Playlist? {
    didSet {
      UserDefaults.standard.set(chillPlaylist?.id.rawValue, forKey: Keys.chill)
      Task { chillTracks = await tracks(of: chillPlaylist) }
    }
  }

  var energyPlaylist: Playlist? {
    didSet {
      UserDefaults.standard.set(energyPlaylist?.id.rawValue, forKey: Keys.energy)
      Task { energyTracks = await tracks(of: energyPlaylist) }
    }
  }

  /// When on, an energy change immediately skips to a matching song. When off
  /// (the default), a matching song is appended after a short delay instead.
  var autoSkip: Bool {
    didSet { UserDefaults.standard.set(autoSkip, forKey: Keys.autoSkip) }
  }

  private let player = ApplicationMusicPlayer.shared
  private var chillTracks: [Track] = []
  private var energyTracks: [Track] = []

  // Energy-adaptation state.
  private var pendingTask: Task<Void, Never>?
  private var lastActedEnergy: EnergyLevel?
  private var lastActionTime = Date.distantPast
  private var hasStarted = false

  private let queueDelay: Double = 12      // seconds before appending in queue mode
  private let requeueInterval: Double = 30 // re-feed sustained energy this often

  private enum Keys {
    static let chill = "chillPlaylistID"
    static let energy = "energyPlaylistID"
    static let autoSkip = "autoSkipOnEnergyChange"
  }

  init() {
    autoSkip = UserDefaults.standard.bool(forKey: Keys.autoSkip)
  }

  var isReady: Bool { chillPlaylist != nil && energyPlaylist != nil }

  // MARK: - Authorization & library

  func requestAuthorization() async {
    let status = await MusicAuthorization.request()
    authState = status == .authorized ? .authorized : .denied
    if authState == .authorized { await loadLibrary() }
  }

  func loadLibrary() async {
    isLoadingLibrary = true
    defer { isLoadingLibrary = false }
    do {
      var request = MusicLibraryRequest<Playlist>()
      request.limit = 100
      let response = try await request.response()
      libraryPlaylists = Array(response.items)
      restoreSelections()
    } catch {
      print("Failed to load playlists: \(error)")
    }
  }

  private func restoreSelections() {
    if chillPlaylist == nil, let id = UserDefaults.standard.string(forKey: Keys.chill) {
      chillPlaylist = libraryPlaylists.first { $0.id.rawValue == id }
    }
    if energyPlaylist == nil, let id = UserDefaults.standard.string(forKey: Keys.energy) {
      energyPlaylist = libraryPlaylists.first { $0.id.rawValue == id }
    }
  }

  private func tracks(of playlist: Playlist?) async -> [Track] {
    guard let playlist else { return [] }
    do {
      let detailed = try await playlist.with(.tracks)
      return Array(detailed.tracks ?? [])
    } catch {
      print("Failed to load tracks: \(error)")
      return []
    }
  }

  // MARK: - Transport

  func playPause() async {
    do {
      if player.state.playbackStatus == .playing {
        player.pause()
      } else {
        if !hasStarted { try await startInitialQueue() }
        try await player.play()
      }
    } catch {
      print("Playback error: \(error)")
    }
  }

  func skipForward() async { try? await player.skipToNextEntry() }
  func skipBackward() async { try? await player.skipToPreviousEntry() }

  /// Seed the queue with the chill playlist so there is something to play.
  private func startInitialQueue() async throws {
    let seed = chillTracks.isEmpty ? energyTracks : chillTracks
    guard !seed.isEmpty else { return }
    player.queue = ApplicationMusicPlayer.Queue(for: seed)
    hasStarted = true
  }

  // MARK: - Energy adaptation

  func handleEnergy(_ tempo: Tempo) {
    guard isReady, let energy = energyLevel(for: tempo) else { return }
    let changed = energy != lastActedEnergy
    let elapsed = Date().timeIntervalSince(lastActionTime)

    if autoSkip {
      guard changed else { return }
    } else {
      guard changed || elapsed > requeueInterval else { return }
    }

    // Optimistically record the decision so rapid tempo flicker doesn't pile up.
    lastActedEnergy = energy
    lastActionTime = Date()

    let skip = autoSkip
    pendingTask?.cancel()
    pendingTask = Task { [weak self] in
      guard let self else { return }
      if !skip {
        try? await Task.sleep(for: .seconds(self.queueDelay))
        if Task.isCancelled { return }
      }
      await self.applyEnergy(energy, skip: skip)
    }
  }

  private func energyLevel(for tempo: Tempo) -> EnergyLevel? {
    switch tempo {
    case .fast: .high
    case .slow: .low
    case .steady, .idle: nil
    }
  }

  private func applyEnergy(_ energy: EnergyLevel, skip: Bool) async {
    let pool = energy == .high ? energyTracks : chillTracks
    guard hasStarted, let song = pool.randomElement() else { return }
    do {
      if skip {
        try await player.queue.insert([song], position: .afterCurrentEntry)
        try await player.skipToNextEntry()
      } else {
        try await player.queue.insert([song], position: .tail)
      }
    } catch {
      print("Failed to adapt queue: \(error)")
    }
  }
}
