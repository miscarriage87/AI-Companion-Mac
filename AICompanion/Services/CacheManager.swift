//
//  CacheManager.swift
//  AICompanion
//
//  Created on: May 19, 2025
//

import Foundation
import Combine
import SwiftUI
import os.log

/// Manager for caching frequently used data
class CacheManager: ObservableObject {
    /// Shared instance for singleton access
    static let shared = CacheManager()
    
    /// Cache for storing objects
    private let cache = NSCache<NSString, AnyObject>()
    
    /// Cache for storing images
    private let imageCache = NSCache<NSString, NSImage>()
    
    /// Cache for storing data
    private let dataCache = NSCache<NSString, NSData>()
    
    /// Disk cache for persistent storage
    private let diskCache = DiskCache()
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.aicompanion", category: "CacheManager")
    
    /// Total memory cache hits
    @Published private(set) var memoryCacheHits: Int = 0
    
    /// Total memory cache misses
    @Published private(set) var memoryCacheMisses: Int = 0
    
    /// Total disk cache hits
    @Published private(set) var diskCacheHits: Int = 0
    
    /// Total disk cache misses
    @Published private(set) var diskCacheMisses: Int = 0
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Configure caches
        cache.countLimit = 100
        imageCache.countLimit = 50
        dataCache.countLimit = 50
        
        // Set up notification for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCaches),
            name: NSApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Load cache statistics from user defaults
        loadCacheStatistics()
    }
    
    /// Load cache statistics from user defaults
    private func loadCacheStatistics() {
        let defaults = UserDefaults.standard
        memoryCacheHits = defaults.integer(forKey: "memoryCacheHits")
        memoryCacheMisses = defaults.integer(forKey: "memoryCacheMisses")
        diskCacheHits = defaults.integer(forKey: "diskCacheHits")
        diskCacheMisses = defaults.integer(forKey: "diskCacheMisses")
    }
    
    /// Save cache statistics to user defaults
    private func saveCacheStatistics() {
        let defaults = UserDefaults.standard
        defaults.set(memoryCacheHits, forKey: "memoryCacheHits")
        defaults.set(memoryCacheMisses, forKey: "memoryCacheMisses")
        defaults.set(diskCacheHits, forKey: "diskCacheHits")
        defaults.set(diskCacheMisses, forKey: "diskCacheMisses")
    }
    
    /// Clear memory caches when memory is low
    @objc private func clearMemoryCaches() {
        logger.debug("Clearing memory caches due to memory warning")
        cache.removeAllObjects()
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
    }
    
    // MARK: - Object Cache
    
    /// Store an object in the cache
    func storeObject<T: AnyObject>(_ object: T, forKey key: String) {
        cache.setObject(object, forKey: key as NSString)
        logger.debug("Stored object in memory cache: \(key)")
    }
    
    /// Retrieve an object from the cache
    func retrieveObject<T: AnyObject>(forKey key: String) -> T? {
        if let object = cache.object(forKey: key as NSString) as? T {
            // Cache hit
            DispatchQueue.main.async {
                self.memoryCacheHits += 1
                self.saveCacheStatistics()
            }
            logger.debug("Memory cache hit: \(key)")
            return object
        } else {
            // Cache miss
            DispatchQueue.main.async {
                self.memoryCacheMisses += 1
                self.saveCacheStatistics()
            }
            logger.debug("Memory cache miss: \(key)")
            return nil
        }
    }
    
    /// Remove an object from the cache
    func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        logger.debug("Removed object from memory cache: \(key)")
    }
    
    // MARK: - Image Cache
    
    /// Store an image in the cache
    func storeImage(_ image: NSImage, forKey key: String) {
        imageCache.setObject(image, forKey: key as NSString)
        logger.debug("Stored image in memory cache: \(key)")
    }
    
    /// Retrieve an image from the cache
    func retrieveImage(forKey key: String) -> NSImage? {
        if let image = imageCache.object(forKey: key as NSString) {
            // Cache hit
            DispatchQueue.main.async {
                self.memoryCacheHits += 1
                self.saveCacheStatistics()
            }
            logger.debug("Memory cache hit: \(key)")
            return image
        } else {
            // Cache miss
            DispatchQueue.main.async {
                self.memoryCacheMisses += 1
                self.saveCacheStatistics()
            }
            logger.debug("Memory cache miss: \(key)")
            return nil
        }
    }
    
    /// Remove an image from the cache
    func removeImage(forKey key: String) {
        imageCache.removeObject(forKey: key as NSString)
        logger.debug("Removed image from memory cache: \(key)")
    }
    
    // MARK: - Data Cache
    
    /// Store data in the cache
    func storeData(_ data: Data, forKey key: String) {
        dataCache.setObject(data as NSData, forKey: key as NSString)
        logger.debug("Stored data in memory cache: \(key)")
    }
    
    /// Retrieve data from the cache
    func retrieveData(forKey key: String) -> Data? {
        if let data = dataCache.object(forKey: key as NSString) as Data? {
            // Cache hit
            DispatchQueue.main.async {
                self.memoryCacheHits += 1
                self.saveCacheStatistics()
            }
            logger.debug("Memory cache hit: \(key)")
            return data
        } else {
            // Cache miss
            DispatchQueue.main.async {
                self.memoryCacheMisses += 1
                self.saveCacheStatistics()
            }
            logger.debug("Memory cache miss: \(key)")
            return nil
        }
    }
    
    /// Remove data from the cache
    func removeData(forKey key: String) {
        dataCache.removeObject(forKey: key as NSString)
        logger.debug("Removed data from memory cache: \(key)")
    }
    
    // MARK: - Disk Cache
    
    /// Store data in the disk cache
    func storeToDisk(_ data: Data, forKey key: String) {
        diskCache.store(data, forKey: key)
        logger.debug("Stored data in disk cache: \(key)")
    }
    
    /// Retrieve data from the disk cache
    func retrieveFromDisk(forKey key: String) -> Data? {
        if let data = diskCache.retrieve(forKey: key) {
            // Cache hit
            DispatchQueue.main.async {
                self.diskCacheHits += 1
                self.saveCacheStatistics()
            }
            logger.debug("Disk cache hit: \(key)")
            return data
        } else {
            // Cache miss
            DispatchQueue.main.async {
                self.diskCacheMisses += 1
                self.saveCacheStatistics()
            }
            logger.debug("Disk cache miss: \(key)")
            return nil
        }
    }
    
    /// Remove data from the disk cache
    func removeFromDisk(forKey key: String) {
        diskCache.remove(forKey: key)
        logger.debug("Removed data from disk cache: \(key)")
    }
    
    // MARK: - Combined Cache Operations
    
    /// Store data in both memory and disk cache
    func store(_ data: Data, forKey key: String, persistToDisk: Bool = true) {
        // Store in memory cache
        storeData(data, forKey: key)
        
        // Store in disk cache if requested
        if persistToDisk {
            storeToDisk(data, forKey: key)
        }
    }
    
    /// Retrieve data from cache (memory first, then disk)
    func retrieve(forKey key: String) -> Data? {
        // Try memory cache first
        if let data = retrieveData(forKey: key) {
            return data
        }
        
        // Try disk cache if not in memory
        if let data = retrieveFromDisk(forKey: key) {
            // Store in memory cache for future use
            storeData(data, forKey: key)
            return data
        }
        
        return nil
    }
    
    /// Remove data from both memory and disk cache
    func remove(forKey key: String) {
        removeData(forKey: key)
        removeFromDisk(forKey: key)
        logger.debug("Removed data from all caches: \(key)")
    }
    
    // MARK: - Cache Management
    
    /// Clear all caches
    func clearAllCaches() {
        // Clear memory caches
        cache.removeAllObjects()
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        
        // Clear disk cache
        diskCache.clearAll()
        
        logger.debug("Cleared all caches")
    }
    
    /// Clear expired items from disk cache
    func clearExpiredItems(olderThan date: Date = Date().addingTimeInterval(-7 * 24 * 60 * 60)) {
        diskCache.clearExpired(olderThan: date)
        logger.debug("Cleared expired items from disk cache")
    }
    
    /// Get cache statistics
    func getCacheStatistics() -> CacheStatistics {
        return CacheStatistics(
            memoryCacheHits: memoryCacheHits,
            memoryCacheMisses: memoryCacheMisses,
            diskCacheHits: diskCacheHits,
            diskCacheMisses: diskCacheMisses,
            memoryCacheSize: cache.totalCostLimit,
            diskCacheSize: diskCache.totalSize
        )
    }
    
    /// Reset cache statistics
    func resetCacheStatistics() {
        memoryCacheHits = 0
        memoryCacheMisses = 0
        diskCacheHits = 0
        diskCacheMisses = 0
        saveCacheStatistics()
        logger.debug("Reset cache statistics")
    }
}

/// Disk cache for persistent storage
class DiskCache {
    /// URL for the cache directory
    private let cacheURL: URL
    
    /// File manager for file operations
    private let fileManager = FileManager.default
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.aicompanion", category: "DiskCache")
    
    /// Total size of the disk cache in bytes
    var totalSize: UInt64 {
        return calculateTotalSize()
    }
    
    init() {
        // Get the cache directory URL
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheURL = cachesDirectory.appendingPathComponent("AICompanionCache", isDirectory: true)
        
        // Create the cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        
        // Log cache directory
        logger.debug("Disk cache directory: \(self.cacheURL.path)")
    }
    
    /// Store data in the disk cache
    func store(_ data: Data, forKey key: String) {
        let fileURL = cacheURL.appendingPathComponent(key)
        
        do {
            // Create metadata
            let metadata = CacheMetadata(
                key: key,
                createdAt: Date(),
                accessedAt: Date(),
                size: UInt64(data.count)
            )
            
            // Store metadata
            let metadataURL = fileURL.appendingPathExtension("metadata")
            let metadataData = try JSONEncoder().encode(metadata)
            try metadataData.write(to: metadataURL)
            
            // Store data
            try data.write(to: fileURL)
            
            logger.debug("Stored data in disk cache: \(key) (\(data.count) bytes)")
        } catch {
            logger.error("Failed to store data in disk cache: \(key): \(error.localizedDescription)")
        }
    }
    
    /// Retrieve data from the disk cache
    func retrieve(forKey key: String) -> Data? {
        let fileURL = cacheURL.appendingPathComponent(key)
        
        do {
            // Check if file exists
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            // Update metadata
            let metadataURL = fileURL.appendingPathExtension("metadata")
            if fileManager.fileExists(atPath: metadataURL.path),
               var metadata = try? JSONDecoder().decode(CacheMetadata.self, from: Data(contentsOf: metadataURL)) {
                metadata.accessedAt = Date()
                let metadataData = try JSONEncoder().encode(metadata)
                try metadataData.write(to: metadataURL)
            }
            
            // Read data
            let data = try Data(contentsOf: fileURL)
            
            logger.debug("Retrieved data from disk cache: \(key) (\(data.count) bytes)")
            
            return data
        } catch {
            logger.error("Failed to retrieve data from disk cache: \(key): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Remove data from the disk cache
    func remove(forKey key: String) {
        let fileURL = cacheURL.appendingPathComponent(key)
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        do {
            // Remove data file
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            
            // Remove metadata file
            if fileManager.fileExists(atPath: metadataURL.path) {
                try fileManager.removeItem(at: metadataURL)
            }
            
            logger.debug("Removed data from disk cache: \(key)")
        } catch {
            logger.error("Failed to remove data from disk cache: \(key): \(error.localizedDescription)")
        }
    }
    
    /// Clear all data from the disk cache
    func clearAll() {
        do {
            // Remove cache directory
            if fileManager.fileExists(atPath: cacheURL.path) {
                try fileManager.removeItem(at: cacheURL)
            }
            
            // Recreate cache directory
            try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
            
            logger.debug("Cleared all data from disk cache")
        } catch {
            logger.error("Failed to clear disk cache: \(error.localizedDescription)")
        }
    }
    
    /// Clear expired items from the disk cache
    func clearExpired(olderThan date: Date) {
        do {
            // Get all files in cache directory
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            
            // Filter metadata files
            let metadataURLs = fileURLs.filter { $0.pathExtension == "metadata" }
            
            // Check each metadata file
            for metadataURL in metadataURLs {
                do {
                    // Read metadata
                    let metadata = try JSONDecoder().decode(CacheMetadata.self, from: Data(contentsOf: metadataURL))
                    
                    // Check if expired
                    if metadata.accessedAt < date {
                        // Remove data file
                        let key = metadataURL.deletingPathExtension().lastPathComponent
                        remove(forKey: key)
                    }
                } catch {
                    logger.error("Failed to process metadata file: \(metadataURL.path): \(error.localizedDescription)")
                }
            }
            
            logger.debug("Cleared expired items from disk cache")
        } catch {
            logger.error("Failed to clear expired items from disk cache: \(error.localizedDescription)")
        }
    }
    
    /// Calculate the total size of the disk cache
    private func calculateTotalSize() -> UInt64 {
        do {
            // Get all files in cache directory
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey])
            
            // Sum file sizes
            var totalSize: UInt64 = 0
            for fileURL in fileURLs {
                let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = attributes.fileSize {
                    totalSize += UInt64(fileSize)
                }
            }
            
            return totalSize
        } catch {
            logger.error("Failed to calculate disk cache size: \(error.localizedDescription)")
            return 0
        }
    }
}

/// Metadata for cached items
struct CacheMetadata: Codable {
    /// Key for the cached item
    let key: String
    
    /// Time when the item was created
    let createdAt: Date
    
    /// Time when the item was last accessed
    var accessedAt: Date
    
    /// Size of the cached item in bytes
    let size: UInt64
}

/// Statistics for the cache
struct CacheStatistics {
    /// Total memory cache hits
    let memoryCacheHits: Int
    
    /// Total memory cache misses
    let memoryCacheMisses: Int
    
    /// Total disk cache hits
    let diskCacheHits: Int
    
    /// Total disk cache misses
    let diskCacheMisses: Int
    
    /// Size of the memory cache in bytes
    let memoryCacheSize: Int
    
    /// Size of the disk cache in bytes
    let diskCacheSize: UInt64
    
    /// Total cache hits
    var totalHits: Int {
        return memoryCacheHits + diskCacheHits
    }
    
    /// Total cache misses
    var totalMisses: Int {
        return memoryCacheMisses + diskCacheMisses
    }
    
    /// Memory cache hit rate
    var memoryCacheHitRate: Double {
        let total = memoryCacheHits + memoryCacheMisses
        return total > 0 ? Double(memoryCacheHits) / Double(total) : 0
    }
    
    /// Disk cache hit rate
    var diskCacheHitRate: Double {
        let total = diskCacheHits + diskCacheMisses
        return total > 0 ? Double(diskCacheHits) / Double(total) : 0
    }
    
    /// Overall cache hit rate
    var overallHitRate: Double {
        let total = totalHits + totalMisses
        return total > 0 ? Double(totalHits) / Double(total) : 0
    }
}
