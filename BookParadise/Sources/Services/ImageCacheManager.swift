import Foundation
import UIKit
import CryptoKit
import ImageIO

public final class ImageCacheManager {
    public static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskQueue = DispatchQueue(label: "com.bookparadise.imagecache.disk", qos: .utility)
    
    private var cacheFolderURL: URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let folder = caches.appendingPathComponent("BookCovers", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    private init() {
        // Ограничение памяти: максимум 200 обложек или 80 МБ
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 80 * 1024 * 1024
    }
    
    // MARK: - Хэширование URL в имя файла
    private func cacheKey(for url: URL) -> NSString {
        return url.absoluteString as NSString
    }
    
    private func diskFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hexString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheFolderURL.appendingPathComponent("\(hexString).jpg")
    }
    
    // MARK: - Синхронная проверка в оперативной памяти (0 мс)
    public func cachedImageInMemory(for url: URL) -> UIImage? {
        return memoryCache.object(forKey: cacheKey(for: url))
    }
    
    // MARK: - Асинхронная загрузка с двухуровневым кэшированием
    public func loadImage(from url: URL, targetSize: CGSize = CGSize(width: 320, height: 480)) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // 1. Уровень 1: Оперативная память (RAM)
        if let memImage = memoryCache.object(forKey: key) {
            return memImage
        }
        
        // 2. Уровень 2: Локальный диск (Disk Cache)
        let diskURL = diskFileURL(for: url)
        if fileManager.fileExists(atPath: diskURL.path),
           let diskData = try? Data(contentsOf: diskURL),
           let diskImage = downsample(imageData: diskData, to: targetSize) {
            let cost = diskData.count
            memoryCache.setObject(diskImage, forKey: key, cost: cost)
            return diskImage
        }
        
        // 3. Уровень 3: Загрузка по сети
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  !data.isEmpty else {
                return nil
            }
            
            // Сохранение на диск в фоновом потоке
            diskQueue.async { [weak self] in
                guard self != nil else { return }
                try? data.write(to: diskURL, options: [.atomic])
            }
            
            // Сжатие и добавление в RAM
            if let decodedImage = downsample(imageData: data, to: targetSize) {
                memoryCache.setObject(decodedImage, forKey: key, cost: data.count)
                return decodedImage
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: - Предзагрузка (Prefetching) для плавного скролла
    public func prefetch(urls: [URL]) {
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            for url in urls {
                if self.cachedImageInMemory(for: url) == nil {
                    _ = await self.loadImage(from: url)
                }
            }
        }
    }
    
    // MARK: - Управление дисковым пространством
    public func clearAllCache() {
        memoryCache.removeAllObjects()
        diskQueue.async { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.cacheFolderURL)
            try? self.fileManager.createDirectory(at: self.cacheFolderURL, withIntermediateDirectories: true)
        }
    }
    
    public func diskCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheFolderURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for file in files {
            if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        return total
    }
    
    public func formattedCacheSize() -> String {
        let bytes = diskCacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Downsampling (умное сжатие картинок через ImageIO)
    private func downsample(imageData: Data, to pointSize: CGSize, scale: CGFloat = 2.0) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            return UIImage(data: imageData)
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return UIImage(data: imageData)
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}
