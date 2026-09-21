// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class AppDelegate : UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    configureNeonAppearance()
    return ServiceManager.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureNeonAppearance() {
    let cyan = UIColor(red: 0.10, green: 0.86, blue: 1.00, alpha: 1.0)
    let magenta = UIColor(red: 1.00, green: 0.18, blue: 0.78, alpha: 1.0)

    UINavigationBar.appearance().tintColor = cyan
    UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    UITabBar.appearance().tintColor = cyan
    UISwitch.appearance().onTintColor = magenta
    UIButton.appearance().tintColor = cyan
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    ServiceManager.shared.applicationWillTerminate()
  }
  
  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    ServiceManager.shared.applicationDidReceiveMemoryWarning()
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    ServiceManager.shared.open(url: url, options: options)
  }
  
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
  
  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    //
  }
}
