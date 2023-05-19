//
//  LogMacro.swift
//  LOGTOOL
//
//  Created by wanghong on 2023/5/15.
//

import UIKit

/// 屏幕宽度
let kWHLogScreenWidth = UIScreen.main.bounds.size.width
/// 屏幕高度
let kWHLogScreenHeight = UIScreen.main.bounds.size.height

let WHLogMainColor = UIColor(red: 0/255.0, green: 199/255.0, blue: 139/255.0, alpha: 1)

/// get current keywindow
func WHGetLogKeyWindow() -> UIWindow? {
    return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
}

/// 顶部安全区高度
func WHLogSafeAreaLayoutGuideTop() -> CGFloat {
    let scene = UIApplication.shared.connectedScenes.first
    guard let windowScene = scene as? UIWindowScene else { return 0 }
    guard let window = windowScene.windows.first else { return 0 }
    return window.safeAreaInsets.top
}

/// 底部安全区高度
func WHLogSafeAreaLayoutGuideBottom() -> CGFloat {
    let scene = UIApplication.shared.connectedScenes.first
    guard let windowScene = scene as? UIWindowScene else { return 0 }
    guard let window = windowScene.windows.first else { return 0 }
    return window.safeAreaInsets.bottom
}
