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
      ReceiptQr.register(controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Распознавание QR (УИ) чека по байтам фото через Vision.
///
/// Текст-OCR удалён: разбор позиций выполняет серверный OCR-воркер. Здесь —
/// только QR-детект на устройстве. Определён в файле таргета Runner, а не
/// отдельным .swift — новые файлы не добавляются в Xcode-проект автоматически.
enum ReceiptQr {
  static func register(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "scan/qr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "scanQr",
            let args = call.arguments as? [String: Any],
            let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
            let image = UIImage(data: data), let cg = image.cgImage else {
        result(FlutterError(code: "bad_args", message: "no image bytes", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        var qr: String?
        let qrReq = VNDetectBarcodesRequest { req, _ in
          for obs in (req.results as? [VNBarcodeObservation]) ?? []
          where obs.symbology == .qr {
            if let p = obs.payloadStringValue { qr = p; break }
          }
        }
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([qrReq])
        DispatchQueue.main.async { result(["qr": qr as Any]) }
      }
    }
  }
}
