// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class JitWaitViewController: UIViewController {
  @objc weak var delegate: JitWaitViewControllerDelegate?
  @IBOutlet var stikJITActivityIndicator: UIActivityIndicatorView!
  @IBOutlet var stikJITStatusView: UIStackView!

  var timer: Timer?
  var isShowingError: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkJit), userInfo: nil, repeats: true)

    switch StikJITManager.shared.jitLaunchMode {
    case .waitForDebugger:
      if JitManager.shared().acquisitionError == nil {
        JitManager.shared().acquisitionError = "JIT Launch Mode is set to Wait for Debugger, so built-in JIT has not started. To use Built-in StikJIT, import this device's pairing file and select Built-in StikJIT in Settings > Debug. It requires iOS 17.4 or later, LocalDevVPN, and an installation signed with get-task-allow."
      }
      break
    case .externalStikDebug:
      JitManager.shared().acquireJitByStikDebugURLScheme()
    case .builtInStikJIT:
      guard #available(iOS 17.4, *) else {
        JitManager.shared().acquisitionError = "Built-in StikJIT requires iOS 17.4 or later."
        break
      }
      guard !StikJITManager.shared.isRunningInLiveContainer else {
        JitManager.shared().acquisitionError = "Built-in StikJIT cannot run inside LiveContainer."
        break
      }
      guard StikJITManager.shared.hasPairingFile else {
        JitManager.shared().acquisitionError = "Built-in StikJIT needs this device's pairing file. Import it in Settings > Debug, connect LocalDevVPN, then launch the game again. Your selected JIT mode has been preserved."
        break
      }
      JitManager.shared().acquireJitByStikJIT()
    }

    self.updateStikJITIndicator()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.updateStikJITIndicator()
    self.showAcquisitionErrorIfNecessary()
  }
  
  @objc func checkJit() {
    self.updateStikJITIndicator()

    if (self.isShowingError) {
      return
    }
    
    let manager = JitManager.shared()
    
    manager.recheckIfJitIsAcquired()
    
    if (manager.acquiredJit) {
      self.timer?.invalidate()
      self.delegate?.didFinishJitScreen(result: .jitAcquired, sender: self)
      
      return
    }
    
    self.showAcquisitionErrorIfNecessary()
  }

  func updateStikJITIndicator() {
    let isRunning = JitManager.shared().isStikJITRunning
    self.stikJITStatusView.isHidden = !isRunning

    if isRunning {
      self.stikJITActivityIndicator.startAnimating()
    } else {
      self.stikJITActivityIndicator.stopAnimating()
    }
  }
  
  func showAcquisitionErrorIfNecessary() {
    let manager = JitManager.shared()
    
    if let error = manager.acquisitionError {
      manager.acquisitionError = nil
      self.isShowingError = true
      
      let alertController = UIAlertController(title: DOLCoreLocalizedString("Error"), message: error, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: DOLCoreLocalizedString("OK"), style: .default, handler: {_ in
        self.isShowingError = false
      }))
      
      self.present(alertController, animated: true, completion: nil)
    }
  }
  
  @IBAction func helpPressed(_ sender: Any) {
    let url = URL.init(string: "https://dolphinios.oatmealdome.me/jit-help")
    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
  }
  
  @IBAction func noJitPressed(_ sender: Any) {
    self.timer?.invalidate()
    self.delegate?.didFinishJitScreen(result: .noJitRequested, sender: self)
  }
  
  @IBAction func cancelPressed(_ sender: Any) {
    self.timer?.invalidate()
    self.delegate?.didFinishJitScreen(result: .cancel, sender: self)
  }
}
