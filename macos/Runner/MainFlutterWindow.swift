// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Register title bar color channel.
    let channel = FlutterMethodChannel(
      name: "dev.dspatch/titlebar",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard call.method == "setColor",
            let args = call.arguments as? [String: Int],
            let r = args["r"], let g = args["g"], let b = args["b"]
      else {
        result(FlutterMethodNotImplemented)
        return
      }

      DispatchQueue.main.async {
        guard let window = self else { return }
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(
          red: CGFloat(r) / 255.0,
          green: CGFloat(g) / 255.0,
          blue: CGFloat(b) / 255.0,
          alpha: 1.0
        )
      }
      result(nil)
    }

    super.awakeFromNib()
  }
}
