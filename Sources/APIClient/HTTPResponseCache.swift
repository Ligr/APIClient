import Foundation
import LRUCache

public actor HTTPResponseCache<ItemType: Sendable> {

    private struct CacheItem<CacheValue> {
        let date: Date
        let value: CacheValue

        init(value: CacheValue) {
            self.date = .init()
            self.value = value
        }
    }

    private let timeout: TimeInterval
    private let cache: LRUCache<String, CacheItem<ItemType>>
    private var actionsInProgress: [String: Task<ItemType, Error>] = [:]

    public init(timeout: TimeInterval, size: Int? = nil) {
        self.timeout = timeout
        self.cache = .init(countLimit: size ?? .max)
    }

    public func value(forKey key: String) -> ItemType? {
        if let cachedItem = cache.value(forKey: key) {
            if abs(cachedItem.date.timeIntervalSinceNow) > timeout {
                print("cache expired for: \(key)")
                cache.removeValue(forKey: key)
            } else {
                print("cache hit for: \(key)")
                return cachedItem.value
            }
        }
        return nil
    }

    public func setValue(_ value: ItemType, forKey key: String) {
        print("cache added for: \(key)")
        cache.setValue(.init(value: value), forKey: key)
    }

    /// Try to get value from cache. If value is not in the cache (or cache expired) then "valueAction" will be performed to get new value and cache it
    /// - Parameters:
    ///   - key: value cache key
    ///   - valueAction: action to be performed to get new value
    /// - Returns: value either from the cache or newly created using "valueAction"
    public func value(forKey key: String, valueAction: @escaping @Sendable () async throws -> ItemType) async throws -> ItemType {
        // try to return cached value first
        if let cachedValue = value(forKey: key) {
            return cachedValue
        }
        // maybe action is already in progress - return it's value
        if let inProgress = actionsInProgress[key] {
            print("cache action in progress for: \(key)")
            return try await inProgress.value
        }
        // start a new action to get value
        let actionTask = Task {
            try await valueAction()
        }
        actionsInProgress[key] = actionTask
        defer {
            actionsInProgress.removeValue(forKey: key)
        }
        let value = try await actionTask.value
        setValue(value, forKey: key)
        return value
    }
}
