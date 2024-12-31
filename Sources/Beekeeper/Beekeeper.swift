//
//  Beekeeper.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 14.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation
import AsyncAlgorithms
import Clocks

public enum RequestError {
    case invalidRequest
    case invalidHTTPResponse
    case emptyErrorResponse(httpStatusCode: Int)
    case emptyResponse
}

extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidRequest: return "Invalid request"
        case .invalidHTTPResponse: return "Invalid HTTP response"
        case let .emptyErrorResponse(httpStatusCode): return "Invalid error response with status code \(httpStatusCode)"
        case .emptyResponse: return "Unexpected empty response"
        }
    }
}

public protocol BeekeeperType: Sendable {
    func start() async
    func stop() async
    
    func setInstallDate(_ installDate: Date) async
    func setPropertyCount(_ count: Int) async
    func setProperty(_ index: Int, value: String?) async
    func track(name: String, group: String, detail: String?, value: Double?, custom: [String?]?) async
    func dispatch() async
}

extension Array {
    func element(at index: Int) -> Element? {
        return index < count ? self[index] : nil
    }
}

let memoryKey = "_Beekeeper"

public actor Beekeeper: BeekeeperType {
    
    // MARK: Dependencies
    internal var storage: Storage
    internal var queue: Queue<Event>
    internal var dispatcher: Dispatcher
    internal var clock: AnyClock<Duration>
    
    // MARK: Internal
    
    internal let product: String
    internal var isActive: Bool = false
    internal var dispatchTask: Task<Void, Never>?
    
    private var memory: Memory {
        didSet {
            try? storage.set(value: memory, for: memoryKey)
        }
    }
    
    internal var queueCount: Int {
        queue.count
    }
    
    public init(product: String, dispatcher: Dispatcher, storage: Storage = UserDefaults.standard, queue: Queue<Event> = Queue<Event>(), clock: AnyClock<Duration> = .init(.continuous)) {
        self.product = product
        self.storage = storage
        self.queue = queue
        self.dispatcher = dispatcher
        self.clock = clock
        
        self.memory = storage.value(for: memoryKey) ?? Memory()
    }
    
    private func queue(event: Event) {
        queue.enqueue(item: event)
    }
    
    private func startTimer() async {
        guard isActive, dispatchTask == nil else { return }
        
        await self.dispatch()
        
        let dispatchTimer = AsyncTimerSequence.repeating(every: .seconds(dispatcher.timeout), clock: clock)
        dispatchTask = Task {
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
        guard let dispatchTask else { return false }
        return !dispatchTask.isCancelled
    }
}

extension Beekeeper {
    
    public var optedOut: Bool {
        memory.optedOut
    }
    
    public func setOptedOut(_ optedOut: Bool) async {
        memory.optedOut = optedOut
    }
    
    public func start() async {
        isActive = true
        await startTimer()
    }
    
    public func stop() {
        isActive = false
        stopTimer()
    }
    
    public func isRunning() -> Bool {
        return isActive && (dispatchTask != nil)
    }
    
    public func track(name: String, group: String, detail: String? = nil, value: Double? = nil, custom: [String?]? = nil) async {
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
        await track(event: event)
    }
    
    private func overwrite<T>(array lhs: [T?], with rhs: [T?]) -> [T?] {
        let length = max(lhs.count, rhs.count)
        var result = Array<T?>(repeating: nil, count: length)
        for i in 0..<length {
            result[i] = (rhs.element(at: i) ?? nil) ?? (lhs.element(at: i) ?? nil)
        }
        return result
    }
    
    public func track(event: Event) async {
        guard !optedOut else { return }
        
        memory.memorize(event: event)
        queue(event: event)
        
        if (!isTimerRunning()) {
            await startTimer()
        }
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
        
        do {
            try await dispatcher.dispatch(events: events)
        } catch {
            queue.enqueue(items: events)
        }
    }
    
    public func reset() {
        self.memory = Memory()
        self.queue.remove()
    }
}

public extension Beekeeper {
    init(product: String, baseURL: URL, secret: String) {
        let signer = RequestSigner(secret: secret)
        let path = "/\(product)"
        let dispatcher = URLDispatcher(baseURL: baseURL, path: path, signer: signer)
        self.init(product: product, dispatcher: dispatcher)
    }
    
    func track(name: String, group: String, detail: String? = nil) async {
        await track(name: name, group: group, detail: detail, value: nil)
    }
    
    func trackValue(name: String, group: String, detail: String? = nil, value: NSNumber) async {
        let double = value.doubleValue
        await track(name: name, group: group, detail: detail, value: double)
    }
}
