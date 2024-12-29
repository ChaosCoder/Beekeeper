//
//  Beekeeper.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 14.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation
import ConvAPI
import AsyncAlgorithms

@MainActor
public protocol BeekeeperType {
    func start()
    func stop()
    
    func setInstallDate(_ installDate: Date)
    func setPropertyCount(_ count: Int)
    func setProperty(_ index: Int, value: String?)
    func track(name: String, group: String, detail: String?, value: Double?, custom: [String?]?)
    func dispatch() async
}

extension Array {
    func element(at index: Int) -> Element? {
        return index < count ? self[index] : nil
    }
}

let memoryKey = "_Beekeeper"

@MainActor
public class Beekeeper: NSObject, BeekeeperType {
    
    // MARK: Dependencies
    internal var storage: Storage
    internal var queue: Queue<Event>
    internal var dispatcher: Dispatcher
    
    // MARK: Internal
    
    internal let product: String
    internal var isActive: Bool = false
    internal var dispatchTask: Task<Void, Never>?
    
    private var memory: Memory {
        didSet {
            try? storage.set(value: memory, for: memoryKey)
        }
    }
    
    public init(product: String, dispatcher: Dispatcher, storage: Storage = UserDefaults.standard, queue: Queue<Event> = Queue<Event>()) {
        self.product = product
        self.storage = storage
        self.queue = queue
        self.dispatcher = dispatcher
        
        self.memory = storage.value(for: memoryKey) ?? Memory()
        
        super.init()
    }
    
    private func queue(event: Event) {
        queue.enqueue(item: event)
    }
    
    private func startTimer() {
        guard isActive, dispatchTask == nil else { return }
        
        let dispatchTimer = AsyncTimerSequence.repeating(every: .seconds(dispatcher.timeout))
        
        dispatchTask = Task.detached {
            for await _ in dispatchTimer {
                await self.dispatch()
            }
        }
    }
    
    private func stopTimer() {
        dispatchTask?.cancel()
        dispatchTask = nil
    }
    
    private func isTimerRunning() -> Bool {
        return dispatchTask != nil || !dispatchTask!.isCancelled
    }
}

extension Beekeeper {
    
    public var optedOut: Bool {
        get {
            return memory.optedOut
        }
        set {
            memory.optedOut = newValue
        }
    }
    
    public func start() {
        isActive = true
        startTimer()
    }
    
    public func stop() {
        isActive = false
        stopTimer()
    }
    
    public func isRunning() -> Bool {
        return isActive && (dispatchTask != nil)
    }
    
    public func track(name: String, group: String, detail: String? = nil, value: Double? = nil, custom: [String?]? = nil) {
        let mergedCustom: [String?]
        if let overwriteValues = custom {
            mergedCustom = overwrite(array: memory.custom, with: overwriteValues)
        } else {
            mergedCustom = memory.custom
        }
        let event = Event(id: UUID().uuidString.replacingOccurrences(of: "-", with: ""),
                          product: product,
                          timestamp: Date(),
                          name: name,
                          group: group,
                          detail: detail,
                          value: value,
                          previousEvent: memory.previousEvent(group: group),
                          previousEventTimestamp: memory.lastTimestamp(eventName: name, eventGroup: group),
                          install: memory.installDay,
                          custom: mergedCustom)
        track(event: event)
    }
    
    private func overwrite<T>(array lhs: [T?], with rhs: [T?]) -> [T?] {
        let length = max(lhs.count, rhs.count)
        var result = Array<T?>(repeating: nil, count: length)
        for i in 0..<length {
            result[i] = (rhs.element(at: i) ?? nil) ?? (lhs.element(at: i) ?? nil)
        }
        return result
    }
    
    public func track(event: Event) {
        guard !optedOut else { return }
        
        memory.memorize(event: event)
        queue(event: event)
    }
    
    public func setInstallDate(_ installDate: Date) {
        memory.installDay = installDate.day
    }
    
    public func setPropertyCount(_ count: Int) {
        if count > memory.custom.count {
            memory.custom.append(contentsOf: [String?].init(repeating: nil, count: count - memory.custom.count))
        } else if count < memory.custom.count {
            memory.custom.removeSubrange(count..<memory.custom.count)
        }
    }
    
    public func setProperty(_ index: Int, value: String?) {
        if index >= memory.custom.count {
            setPropertyCount(index + 1)
        }
        
        memory.custom[index] = value
    }
    
    public func dispatch() async {
        guard isActive, !optedOut else {
            return
        }
        
        let events = queue.remove(max: dispatcher.maxBatchSize)
        
        guard events.count > 0 else {
            stopTimer()
            return
        }
        
        Task { [dispatcher] in
            do {
                try await dispatcher.dispatch(events: events)
            } catch {
                queue.enqueue(items: events)
            }
        }
    }
    
    public func reset() {
        self.memory = Memory()
        self.queue.remove()
    }
}

public extension Beekeeper {
    convenience init(product: String, baseURL: URL, secret: String) {
        let signer = RequestSigner(secret: secret)
        let path = "/\(product)"
        let dispatcher = URLDispatcher(baseURL: baseURL, path: path, signer: signer)
        self.init(product: product, dispatcher: dispatcher)
    }
    
    func track(name: String, group: String, detail: String? = nil) {
        track(name: name, group: group, detail: detail, value: nil)
    }
    
    func trackValue(name: String, group: String, detail: String? = nil, value: NSNumber) {
        let double = value.doubleValue
        track(name: name, group: group, detail: detail, value: double)
    }
}
