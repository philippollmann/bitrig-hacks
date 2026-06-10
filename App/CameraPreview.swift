import AVFoundation
import SwiftUI

/// A SwiftUI wrapper around an `AVCaptureVideoPreviewLayer`-backed view.
struct CameraPreview: UIViewRepresentable {
  let session: AVCaptureSession

  func makeUIView(context: Context) -> PreviewView {
    let view = PreviewView()
    view.previewLayer.session = session
    view.previewLayer.videoGravity = .resizeAspectFill
    if let connection = view.previewLayer.connection {
      connection.automaticallyAdjustsVideoMirroring = false
      connection.isVideoMirrored = true
      if connection.isVideoRotationAngleSupported(90) {
        connection.videoRotationAngle = 90
      }
    }
    return view
  }

  func updateUIView(_ uiView: PreviewView, context: Context) {}

  /// A view whose backing layer is the capture preview layer.
  final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
  }
}
