//
//  LogView.swift
//  LOGTOOL
//
//  Created by wanghong on 2023/5/15.
//

import UIKit

class WHLogView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.creatUI()
    }
    
    func creatUI() {
        self.backgroundColor = .white
        self.addSubview(containerView)
        containerView.addArrangedSubview(memoryShowLabel)
        containerView.addArrangedSubview(cpuShowLabel)
        containerView.addArrangedSubview(fpsShowLabel)
        containerView.addArrangedSubview(readButton)
        containerView.addArrangedSubview(clearButton)
        self.addSubview(textView)
        // 设备开始监测
        deviceMonitor.startMonitor()
//        LogDataMonitor.shared.logOutputdelegate = self
        let panGestrure = UIPanGestureRecognizer(target: self, action: #selector(self.panAction(pan:)))
        self.addGestureRecognizer(panGestrure)
    }
    // 读取日志
    @objc func readBtnAction() {
        self.textView.text = ""
        let log = WHLogDataMonitor.shared.readLogFromFile()
        self.showLog(str: log)
    }
    // 显示日志
    func showLog(str: String) {
        // 将新的日志拼接到后面
        var logStr = self.textView.text ?? ""
        let logArray = str.components(separatedBy: "\r\n")
        for fragmentStr in logArray {
            logStr += fragmentStr
        }
        self.textView.text = logStr
        // 滚动到底部
        self.textView.scrollRangeToVisible(NSRange(location: 0, length: self.textView.text.count))
    }
    // 清理打印的日志
    @objc func clearBtnAction() {
        // 清除的时候只清除显示的日志，不清除本地文件，方便取出来查看
//        LogDataMonitor.shared.clearLogFromFile()
        self.textView.text = ""
    }
    // 日志视图tuo do
    @objc func panAction(pan: UIPanGestureRecognizer) {
        let currentPoint = pan.translation(in: self.superview)
        self.center = CGPoint(x: self.center.x + currentPoint.x, y: self.center.y + currentPoint.y)
        pan.setTranslation(CGPointZero, in: self.superview)
    }
    
    // 设备监测类
    lazy var deviceMonitor: WHDeviceDataMonitor = {
        let deviceMonitor = WHDeviceDataMonitor()
        deviceMonitor.cpuDataMonitor = { [weak self] value in
            self?.cpuShowLabel.text = String(format: "CPU:%.0f %%", value)
        }
        deviceMonitor.fpsDataMonitor = { [weak self] value in
            self?.fpsShowLabel.text = String(format: "%.0f FPS", value)
        }
        deviceMonitor.memoryDataMonitor = { [weak self] value in
            self?.memoryShowLabel.text = String(format: "%.01f M", value)
        }
        return deviceMonitor
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView(frame: CGRect(x: 5, y: 30, width: self.bounds.size.width-10, height: self.bounds.size.height - 30))
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
    }()
    
    lazy var containerView: UIStackView = {
        let containerView = UIStackView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 30))
        containerView.axis = .horizontal
        containerView.distribution = .fillEqually
        containerView.spacing = 10;
        containerView.alignment = .fill
        return containerView
    }()
    
    lazy var memoryShowLabel: UILabel = {
        let memoryShowLabel = UILabel()
        memoryShowLabel.text = "_ _"
        memoryShowLabel.textColor = .white
        memoryShowLabel.layer.cornerRadius = 2
        memoryShowLabel.layer.masksToBounds = true
        memoryShowLabel.adjustsFontSizeToFitWidth = true
        memoryShowLabel.textAlignment = .center
        memoryShowLabel.backgroundColor = WHLogMainColor
        return memoryShowLabel
    }()
    
    lazy var cpuShowLabel: UILabel = {
        let cpuShowLabel = UILabel()
        cpuShowLabel.text = "_ _"
        cpuShowLabel.textColor = .white
        cpuShowLabel.layer.cornerRadius = 2
        cpuShowLabel.layer.masksToBounds = true
        cpuShowLabel.adjustsFontSizeToFitWidth = true
        cpuShowLabel.textAlignment = .center
        cpuShowLabel.backgroundColor = WHLogMainColor
        return cpuShowLabel
    }()
    
    lazy var fpsShowLabel: UILabel = {
        let fpsShowLabel = UILabel()
        fpsShowLabel.text = "_ _"
        fpsShowLabel.textColor = .white
        fpsShowLabel.layer.cornerRadius = 2
        fpsShowLabel.layer.masksToBounds = true
        fpsShowLabel.adjustsFontSizeToFitWidth = true
        fpsShowLabel.textAlignment = .center
        fpsShowLabel.backgroundColor = WHLogMainColor
        return fpsShowLabel
    }()
    
    lazy var readButton: UIButton = {
        let readButton = UIButton()
        readButton.layer.cornerRadius = 2
        readButton.layer.masksToBounds = true
        readButton.setTitle("读取", for: .normal)
        readButton.addTarget(self, action: #selector(self.readBtnAction), for: .touchUpInside)
        readButton.backgroundColor = WHLogMainColor
        return readButton
    }()
    
    lazy var clearButton: UIButton = {
        let clearButton = UIButton()
        clearButton.layer.cornerRadius = 2
        clearButton.layer.masksToBounds = true
        clearButton.setTitle("清除", for: .normal)
        clearButton.addTarget(self, action: #selector(self.clearBtnAction), for: .touchUpInside)
        clearButton.backgroundColor = WHLogMainColor
        return clearButton
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WHLogView: WHLogOutputProtocol {
    // 实时打印日志
    func logOutput(content: String) {
//        self.showLog(str: content)
    }
}
