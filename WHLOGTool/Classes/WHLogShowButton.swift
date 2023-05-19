//
//  LogShowButton.swift
//  LOGTOOL
//
//  Created by wanghong on 2023/5/15.
//

import UIKit

class WHLogShowButton: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.creatUI()
    }
    /// 显示日志开关按钮
    static func show() {
        let logBtn = WHLogShowButton(frame: CGRect(x: kWHLogScreenWidth - 60,
                                                 y: kWHLogScreenHeight - 150 - WHLogSafeAreaLayoutGuideBottom(),
                                                 width: 50,
                                                 height: 50))
        WHGetLogKeyWindow()?.addSubview(logBtn)
        // 日志开始监测
        WHLogDataMonitor.shared.startMonitorSystemLog()
    }
    
    func creatUI() {
        self.backgroundColor = WHLogMainColor
        self.layer.shadowColor = WHLogMainColor.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = self.bounds.size.width / 2.0
        self.layer.cornerRadius = self.bounds.size.width / 2.0
        self.layer.masksToBounds = false
        self.addSubview(self.titleLabel)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.logBtnClickProcess))
        self.addGestureRecognizer(tap)
    }
    // 显示/隐藏日志视图
    @objc func logBtnClickProcess(tap: UIGestureRecognizer) {
        self.logView.isHidden = !self.logView.isHidden
    }
    // 日志查看视图
    lazy var logView: WHLogView = {
        let pointY = (kWHLogScreenHeight - WHLogSafeAreaLayoutGuideTop() - WHLogSafeAreaLayoutGuideBottom() + 20) / 3
        let logView = WHLogView(frame: CGRect(x: 0, y: pointY, width: kWHLogScreenWidth, height: pointY * 2))
        logView.isHidden = true
        WHGetLogKeyWindow()?.addSubview(logView)
        return logView
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: self.bounds)
        label.text = "LOG"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    // 按钮跟随拖动
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentPoint = touches.first?.location(in: self.superview) {
            self.center = currentPoint
        }
    }
    // 按钮停止拖动时，吸附到屏幕边缘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.toucheProcess(touches: touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.toucheProcess(touches: touches)
    }
    @objc func panAction(pan: UIPanGestureRecognizer) {
        let currentPoint = pan.translation(in: self.superview)
        self.center = CGPoint(x: self.center.x + currentPoint.x, y: self.center.y + currentPoint.y)
        pan.setTranslation(CGPointZero, in: self.superview)
    }
    func toucheProcess(touches: Set<UITouch>) {
        let margin = 10.0
        if var currentPoint = touches.first?.location(in: self.superview) {
            if currentPoint.y < self.bounds.size.height / 2 {
                currentPoint.y = self.bounds.size.height / 2.0 + margin
            }
            if currentPoint.y > kWHLogScreenHeight - self.bounds.size.height / 2.0 {
                currentPoint.y = kWHLogScreenHeight - self.bounds.size.height / 2.0 - margin
            }
            if currentPoint.x >= kWHLogScreenWidth / 2.0 {
                currentPoint.x = kWHLogScreenWidth - self.bounds.size.width / 2.0 - margin
            } else {
                currentPoint.x = self.bounds.size.width / 2.0 + margin
            }
            UIView.animate(withDuration: 0.5) {
                self.center = currentPoint
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
