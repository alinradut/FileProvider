//
//  ThreadSafeDictionary.swift
//  FilesProvider
//
//  Created by Alin Radut on 6/23/23.
//

import Foundation

/// A drop-in replacement thread-safe dictionary which allows concurrent reading and blocks on writes.
public class ThreadSafeDictionary<K: Hashable, V> {

    /// Queue to run the operations on.
    private let queue = DispatchQueue(label: "ThreadSafeDictionary.\(K.self.self).\(V.self.self)", attributes: .concurrent)

    fileprivate var dictionary: [K: V]

    /// Initialize a new thread safe dictionary
    /// - Parameter dictionary: Dictionary.
    public init(_ dictionary: [K: V] = [:]) {
        self.dictionary = dictionary
    }

    /// Returns a copy of the underlying dicionary
    public var underlyingDictionary: [K: V] {
        var dictionary: [K: V]!
        queue.sync { dictionary = self.dictionary }
        return dictionary
    }

    /// Dictionary keys
    public var keys: [K] {
        var dictionary: [K: V]!
        queue.sync { dictionary = self.dictionary }
        return Array(dictionary.keys)
    }

    subscript(key: K) -> V? {
        get {
            queue.sync {
                return dictionary[key]
            }
        }
        set {
            self.queue.async(flags: .barrier) {
                self.dictionary[key] = newValue
            }
        }
    }

    func removeValue(forKey key: K) -> V? {
        var value: V? = self[key]
        self.queue.async(flags: .barrier) {
            self.dictionary.removeValue(forKey: key)
        }
        return value
    }

    func removeAll() {
        self.queue.async(flags: .barrier) {
            self.dictionary.removeAll()
        }
    }

    func forEach(_ body: ((key: K, value: V)) throws -> Void) {
        queue.sync {
            try? self.dictionary.forEach(body)
        }
    }

    func compactMap<R>(_ transform: ((key: K, value: V)) -> R?) -> [R] {
        queue.sync {
            self.dictionary.compactMap(transform)
        }
    }

    func replaceAll(with newValue: [K: V]) {
        queue.async(flags: .barrier) {
            self.dictionary = newValue
        }
    }
}
