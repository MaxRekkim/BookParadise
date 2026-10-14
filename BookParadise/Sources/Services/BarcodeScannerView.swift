import SwiftUI
import AVFoundation
#if canImport(VisionKit)
import VisionKit
#endif

public struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding public var scannedCode: String
    @Environment(\.dismiss) private var dismiss
    public var onScan: (String) -> Void
    
    public init(scannedCode: Binding<String>, onScan: @escaping (String) -> Void) {
        self._scannedCode = scannedCode
        self.onScan = onScan
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        #if canImport(VisionKit)
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .code128])],
                qualityLevel: .balanced,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isPinchToZoomEnabled: true,
                isGuidanceEnabled: true,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            try? scanner.startScanning()
            return scanner
        }
        #endif
        
        // Fallback: AVFoundation
        let controller = AVScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, @unchecked Sendable {
        var parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func handleCode(_ code: String) {
            let clean = code.replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            DispatchQueue.main.async {
                self.parent.scannedCode = clean
                self.parent.onScan(clean)
                self.parent.dismiss()
            }
        }
    }
}

#if canImport(VisionKit)
extension BarcodeScannerView.Coordinator: DataScannerViewControllerDelegate {
    public func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        for item in addedItems {
            switch item {
            case .barcode(let barcode):
                if let payload = barcode.payloadStringValue {
                    handleCode(payload)
                    return
                }
            default:
                break
            }
        }
    }
}
#endif

// Fallback AVFoundation Scanner
public class AVScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeScannerView.Coordinator?
    private var captureSession: AVCaptureSession?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.ean13, .ean8, .code128]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            captureSession?.stopRunning()
            delegate?.handleCode(stringValue)
        }
    }
}
