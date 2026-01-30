import Flutter
import UIKit
import CoreMotion
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let pedometer = CMPedometer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Workmanager
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "bench_profile/health", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }
        if call.method == "getCurrentMetrics" {
          let args = call.arguments as? [String:Any]
          let sinceMs = args?"since" as? Int64
          let now = Date()
          if CMPedometer.isStepCountingAvailable() {
            let from: Date
            if let s = sinceMs {
              from = Date(timeIntervalSince1970: TimeInterval(s)/1000.0)
            } else {
              from = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? Date()
            }

            self.pedometer.queryPedometerData(from: from, to: now) { data, error in
              if let err = error {
                result(FlutterError(code: "PEDOMETER_ERROR", message: err.localizedDescription, details: nil))
                return
              }

              let steps = data?.numberOfSteps.intValue ?? 0
              let payload: [String:Any?] = [
                "source": "pedometer",
                "steps": steps,
                "heartRate": nil,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
              ]
              result(payload)
            }
          } else {
            let payload: [String:Any?] = [
              "source": "unavailable",
              "steps": nil,
              "heartRate": nil,
              "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
            ]
            result(payload)
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
