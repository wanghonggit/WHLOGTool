//
//  LogDataMonitor.swift
//  LOGTOOL
//
//  Created by wanghong on 2023/5/15.
//

import UIKit
import Foundation
protocol WHLogOutputProtocol {
    func logOutput(content: String)
}
//public func print<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//    let date = dateFormatter.string(from: Date())
//    print("\(date)-->\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
//}
class WHLogDataMonitor: NSObject {
    // 日志输出回调
    var logOutputdelegate: WHLogOutputProtocol? = nil
    // 写入日志信号
    let writeLogSemaphore = DispatchSemaphore(value: 1)
    // 文件管理
    let fileManager = FileManager.default
    // 原字符
    var originalCharacter: Int32 = 0
    // 当前字符
    var currentCharacter: Int32 = 0
    // 原数据
    var lastData: Data?
    // 程序是否在后台
    var bkFlag: Bool?
    
    // 日志监测单例
    static let shared = WHLogDataMonitor()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appDidBackground() {
        self.bkFlag = true
    }
    
    @objc func appWillEnterForeground() {
        self.bkFlag = false
    }
    
    // 开始监测日志数据输出
    func startMonitorSystemLog() {
        let device = UIDevice.current
        // 因为模拟器直接是在电脑运行，可以直接看到日志，所以模拟器不监测日志
        if device.model.hasSuffix("Simulator") {
            return;
        }
        //保存重定向前的文件描述符
        let pipe = Pipe()
        let pipeReadHandle = pipe.fileHandleForReading
        let pipeFileHandle = pipe.fileHandleForWriting.fileDescriptor
        //STDIN_FILENO标准输入描述符（0）
        //STDOUT_FILENO标准输出描述符（1）
        //STDERR_FILENO标准错误描述符（2）
        self.originalCharacter = dup(STDOUT_FILENO) // 重定向前的标识符
        self.currentCharacter = dup2(pipeFileHandle, STDOUT_FILENO) // 当前重定向的标识符
        dup2(pipeFileHandle, STDERR_FILENO)
        NotificationCenter.default.addObserver(self, selector: #selector(self.monitorAction(notification:)), name: FileHandle.readCompletionNotification, object: pipeReadHandle)
        pipeReadHandle.readInBackgroundAndNotify()
        // 异常日志记录
        self.registerExceptionHandler()
    }
    func removeMonitor() {
        dup2(self.originalCharacter, self.currentCharacter)
        // 恢复重定向后需要移除通知监听否则会导致CPU使用率激增，造成程序卡顿
        NotificationCenter.default.removeObserver(self)
    }
    //若某一次打印的数据量过大的话，系统会分几次输出
    @objc func monitorAction(notification: Notification) {
        let data = notification.userInfo?[NSFileHandleNotificationDataItem]
        let parseData = NSMutableData()
        if self.lastData != nil {
            parseData.append(self.lastData!)
            parseData.append(data as! Data)
        } else {
            parseData.append(data as! Data)
        }
        var content = String(data: parseData as Data, encoding: String.Encoding.utf8)
        if content == nil && parseData.length > 0 {
            //本次发送的data不完整无法解析,需要保存本次并与下次读的数据一起解析
            self.lastData = parseData.copy() as? Data
            content = ""
        } else if content == nil && parseData.length == 0 {
            content = ""
            self.lastData = nil
        } else {
            self.lastData = nil
        }
        if content!.count > 0 {
            // 程序在后台时的处理
            if self.bkFlag == true {
                var taskID: UIBackgroundTaskIdentifier?
                UIApplication.shared.beginBackgroundTask {
                    if taskID != nil {
                        UIApplication.shared.endBackgroundTask(taskID!)
                    }
                    taskID = UIBackgroundTaskIdentifier.invalid
                }
                if taskID != UIBackgroundTaskIdentifier.invalid {
                    self.writeLogToFile(log: content!)
                    // 日志回调到外部显示
                    if self.logOutputdelegate != nil {
                        self.logOutputdelegate?.logOutput(content: content!)
                    }
                    if taskID != nil {
                        UIApplication.shared.endBackgroundTask(taskID!)
                    }
                    taskID = UIBackgroundTaskIdentifier.invalid
                } else {
                    taskID = UIBackgroundTaskIdentifier.invalid
                }
            } else {
                self.writeLogToFile(log: content!)
                if self.logOutputdelegate != nil {
                    self.logOutputdelegate?.logOutput(content: content!)
                }
            }
        }
        (notification.object as! FileHandle).readInBackgroundAndNotify()
    }
    // 从文件中读取日志
    func readLogFromFile() -> String {
        let data = NSData(contentsOfFile: self.logFilePath)
        if (data != nil) {
            let log = String(data: data! as Data, encoding: String.Encoding.utf8)
            if (log != nil) {
                return log!
            } else {
                do {
                    try fileManager.removeItem(atPath: self.logFilePath)
                } catch  {
                    
                }
                return "日志数据出错，解析失败；\n自动删除并重建日志文件"
            }
        } else {
            return "本地暂无日志"
        }
    }
    // 日志写入文件中
    func writeLogToFile(log: String) {
        writeLogSemaphore.wait()
        let logData = log.data(using: String.Encoding.utf8) as? NSData
        if !fileManager.fileExists(atPath: self.logFilePath) {
            logData?.write(toFile: self.logFilePath, atomically: true)
        } else {
            let fileHandle = FileHandle(forWritingAtPath: self.logFilePath)
            fileHandle?.seekToEndOfFile()
            fileHandle?.write(logData! as Data)
            fileHandle?.closeFile()
        }
        writeLogSemaphore.signal()
    }
    // 清除日志
    func clearLogFromFile() {
        do {
            try fileManager.removeItem(atPath: self.logFilePath)
        } catch  {
            print("清除日志失败:\(error)")
        }
    }
    // 日志路径
    var logFilePath: String {
        let logDirectory = self.logDirectoryPath
        if !fileManager.fileExists(atPath: logDirectory) {
            do {
                try fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true)
            } catch {
                print("日志文件读取错误")
            }
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        // 每小时一个日志文件
        formatter.dateFormat = "yyyy-MM-dd-HH"
        let dateStr = formatter.string(from: Date())
        return logDirectory.appendingFormat("/%@.txt", dateStr)
    }
    // 日志目录
    var logDirectoryPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let logDirectory = paths.first?.appending("/APPLOG") ?? ""
        return logDirectory
    }
    // 日志文件列表
    var LogFileList: [String] {
        do {
            let lists = try fileManager.contentsOfDirectory(atPath: self.logDirectoryPath)
            return lists
        } catch {
            return [String]()
        }
    }
}
// 异常日志输出
extension WHLogDataMonitor {
    func registerExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let name = exception.name
            let reason = exception.reason
            let symbols = exception.callStackSymbols // 异常发生时的调用栈
            var strSymbols = "" //将调用栈拼成输出日志的字符串
            for str in symbols {
                strSymbols += str
                strSymbols += "\n"
            }
            //获取当前时间
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = formatter.string(from: Date())
            let crashString = "---EXCEPTION_INFO---\n\(dateStr)\nExceptionName：\(name)\nReason：\(reason ?? "")\nCallTrace：\n\(strSymbols)\n\r\n"
            WHLogDataMonitor.shared.writeLogToFile(log: crashString)
        }
    }
}
