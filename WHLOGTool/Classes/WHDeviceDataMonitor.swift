//
//  DeviceDataMonitor.swift
//  LOGTOOL
//
//  Created by wanghong on 2023/5/15.
//

import UIKit
import Foundation

class WHDeviceDataMonitor: NSObject {
    // cpu监测
    var cpuDataMonitor: ((Float) -> Void)?
    // fps监测
    var fpsDataMonitor: ((Float) -> Void)?
    // memory监测
    var memoryDataMonitor: ((Float) -> Void)?
    
    var displayLink: CADisplayLink?
    var lastTimestamp: TimeInterval = 0
    /// 开始监测
    func startMonitor() {
        self.lastTimestamp = 0
        self.fpsMonitor()
    }
    /// 停止监测
    func stopMonitor() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    // fps监测
    func fpsMonitor() {
        self.displayLink = CADisplayLink(target: self, selector: #selector(self.fpsCaculateAction))
        self.displayLink?.add(to: RunLoop.current, forMode: .common)
    }
    
    @objc func fpsCaculateAction() {
        if (self.lastTimestamp == 0) {
            self.lastTimestamp = self.displayLink?.timestamp ?? 0
            return
        }
        var count = 0.0
        count += 1
        let dert: TimeInterval = (self.displayLink?.timestamp ?? 0) - self.lastTimestamp
        if dert < 1 {
            return
        } else {
            self.lastTimestamp = self.displayLink?.timestamp ?? 0
            let fps = Float(count / dert);
            count = 0
            if self.fpsDataMonitor != nil {
                self.fpsDataMonitor!(fps)
            }
            self.cpuMonitor()
            self.memoryMonitor()
        }
    }
    // 监测内存信息
    func memoryMonitor() {
        var memoryUsageInByte: Int64 = 0
        var vmInfo = task_vm_info_data_t()
        var count: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let kernReturn: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        if (kernReturn != KERN_SUCCESS) {
            if self.memoryDataMonitor != nil {
                self.memoryDataMonitor!(-1)
            }
        }
        memoryUsageInByte = Int64(vmInfo.phys_footprint)
        if self.memoryDataMonitor != nil {
            self.memoryDataMonitor!(Float(memoryUsageInByte) / 1024.0 / 1024.0)
        }
    }
    
    // 监测cpu信息
    func cpuMonitor() {
        var kr: kern_return_t
        var thread_list = UnsafeMutablePointer<thread_act_t>.allocate(capacity: 1)
        var thread_count = mach_msg_type_number_t(0)
        var threadInfo = thread_basic_info()
        var thread_info_count: mach_msg_type_number_t
        var stat_thread: UInt32 = 0
        kr = withUnsafeMutablePointer(to: &thread_list) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
              task_threads(mach_task_self_, $0, &thread_count)
            }
        }
        if kr != KERN_SUCCESS {
            if self.cpuDataMonitor != nil {
                self.cpuDataMonitor!(-1)
                return
            }
        }
        if thread_count > 0 {
            stat_thread += thread_count
        }
        var tot_cpu = 0.0;
        for index in 0..<thread_count {
            thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
            kr = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(thread_list[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &thread_info_count)
                }
            }
            if kr != KERN_SUCCESS {
                return;
            }
            let threadBasicInfo = threadInfo as thread_basic_info
            if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                tot_cpu = (tot_cpu + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
            }
        }
        kr = vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: thread_list)), vm_size_t(Int(thread_count) * MemoryLayout<thread_t>.stride))
        assert(kr == KERN_SUCCESS)
        if self.cpuDataMonitor != nil {
            self.cpuDataMonitor!(Float(tot_cpu))
        }
    }
}
