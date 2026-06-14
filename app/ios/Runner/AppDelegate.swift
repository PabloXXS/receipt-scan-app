import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      ReceiptOcr.register(controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Распознавание текста (ru) и QR чека по байтам фото через Vision.
///
/// Определён здесь (в файле, входящем в таргет Runner), а не отдельным .swift —
/// новые файлы не добавляются в Xcode-проект автоматически.
enum ReceiptOcr {
  static func register(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "scan/ocr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeReceipt",
            let args = call.arguments as? [String: Any],
            let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
            let image = UIImage(data: data), let cg = image.cgImage else {
        result(FlutterError(code: "bad_args", message: "no image bytes", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        var lines: [(String, CGFloat)] = []
        let textReq = VNRecognizeTextRequest { req, _ in
          for obs in (req.results as? [VNRecognizedTextObservation]) ?? [] {
            if let c = obs.topCandidates(1).first {
              lines.append((c.string, obs.boundingBox.maxY))
            }
          }
        }
        textReq.recognitionLevel = .accurate
        textReq.recognitionLanguages = ["ru-RU"]
        textReq.usesLanguageCorrection = true

        var qr: String?
        let qrReq = VNDetectBarcodesRequest { req, _ in
          for obs in (req.results as? [VNBarcodeObservation]) ?? []
          where obs.symbology == .qr {
            if let p = obs.payloadStringValue { qr = p; break }
          }
        }

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([textReq, qrReq])
        // Vision: origin внизу-слева → сортировка по maxY убыванию = сверху вниз.
        let ordered = lines.sorted { $0.1 > $1.1 }.map { $0.0 }
        DispatchQueue.main.async {
          result(["lines": ordered, "qr": qr as Any])
        }
      }
    }
  }
}
