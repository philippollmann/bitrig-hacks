import AVFoundation
import Vision

/// Drives the front camera and feeds frames through Vision body-pose detection,
/// pushing the resulting joints to a `PoseTracker` on the main thread.
final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  let session = AVCaptureSession()

  private let output = AVCaptureVideoDataOutput()
  private let queue = DispatchQueue(label: "com.reptrack.camera")
  private let request = VNDetectHumanBodyPoseRequest()
  private var isConfigured = false

  weak var tracker: PoseTracker?

  /// Joints we read each frame, in skeleton-drawing order.
  private let jointNames: [VNHumanBodyPoseObservation.JointName] = [
    .nose, .neck,
    .leftShoulder, .rightShoulder,
    .leftElbow, .rightElbow,
    .leftWrist, .rightWrist,
    .leftHip, .rightHip,
    .leftKnee, .rightKnee,
    .leftAnkle, .rightAnkle,
  ]

  // MARK: - Lifecycle

  func start() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      queue.async { self.configureAndRun() }
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          self.queue.async { self.configureAndRun() }
        } else {
          DispatchQueue.main.async { self.tracker?.cameraDenied = true }
        }
      }
    default:
      DispatchQueue.main.async { self.tracker?.cameraDenied = true }
    }
  }

  func stop() {
    queue.async {
      if self.session.isRunning { self.session.stopRunning() }
    }
  }

  private func configureAndRun() {
    configureIfNeeded()
    if !session.isRunning { session.startRunning() }
  }

  private func configureIfNeeded() {
    guard !isConfigured else { return }
    session.beginConfiguration()
    session.sessionPreset = .hd1280x720

    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
      let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input)
    else {
      session.commitConfiguration()
      DispatchQueue.main.async { self.tracker?.cameraDenied = true }
      return
    }
    session.addInput(input)

    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(self, queue: queue)
    if session.canAddOutput(output) { session.addOutput(output) }

    session.commitConfiguration()
    isConfigured = true
  }

  // MARK: - Frame processing

  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    // .leftMirrored maps the front sensor buffer to an upright, mirrored image
    // that matches the selfie-style preview.
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
    do {
      try handler.perform([request])
    } catch {
      return
    }

    guard let observation = request.results?.first else {
      DispatchQueue.main.async { self.tracker?.clear() }
      return
    }

    var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    for name in jointNames {
      if let point = try? observation.recognizedPoint(name), point.confidence > 0.3 {
        points[name] = point.location
      }
    }

    DispatchQueue.main.async { self.tracker?.update(points) }
  }
}
