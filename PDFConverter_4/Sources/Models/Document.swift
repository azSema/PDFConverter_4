import Foundation
import PDFKit
import UIKit

// Thumbnail cache для оптимизации загрузки изображений
class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func setThumbnail(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: NSString(string: key))
    }
    
    func getThumbnail(forKey key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }
}

struct DocumentDTO: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var pdf: PDFDocument?
    var name: String
    var type: FileType
    var date: Date
    var url: URL?
    var isFavorite: Bool
    var sourcePDFURL: URL? // Ссылка на исходный PDF для изображений
    
    init(id: String = UUID().uuidString,
         pdf: PDFDocument? = nil,
         name: String = "",
         type: FileType = .pdf,
         date: Date = .now,
         url: URL? = nil,
         isFavorite: Bool = false,
         sourcePDFURL: URL? = nil) {
        self.id = id
        self.pdf = pdf
        self.name = name
        self.type = type
        self.date = date
        self.url = url
        self.isFavorite = isFavorite
        self.sourcePDFURL = sourcePDFURL
    }
    
    var thumbnail: UIImage {
        let cacheKey = "thumbnail_\(id)"
        
        // Проверяем кеш
        if let cachedThumbnail = ThumbnailCache.shared.getThumbnail(forKey: cacheKey) {
            return cachedThumbnail
        }
        
        let thumbnailImage: UIImage
        
        switch type {
        case .pdf:
            if let firstPage = pdf?.page(at: 0) {
                thumbnailImage = firstPage.toImage() ?? UIImage(systemName: "doc.fill")!
            } else {
                thumbnailImage = UIImage(systemName: "doc.fill")!
            }
        case .image:
            // Try to load the actual image from URL
            if let url = url,
               let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {
                // Создаем thumbnail размером для UI (64x80)
                let thumbnailSize = CGSize(width: 64, height: 80)
                let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
                thumbnailImage = renderer.image { _ in
                    let aspectRatio = image.size.width / image.size.height
                    let targetRatio = thumbnailSize.width / thumbnailSize.height
                    
                    var drawRect: CGRect
                    if aspectRatio > targetRatio {
                        // Изображение шире, подгоняем по высоте
                        let scaledWidth = thumbnailSize.height * aspectRatio
                        drawRect = CGRect(
                            x: (thumbnailSize.width - scaledWidth) / 2,
                            y: 0,
                            width: scaledWidth,
                            height: thumbnailSize.height
                        )
                    } else {
                        // Изображение выше, подгоняем по ширине
                        let scaledHeight = thumbnailSize.width / aspectRatio
                        drawRect = CGRect(
                            x: 0,
                            y: (thumbnailSize.height - scaledHeight) / 2,
                            width: thumbnailSize.width,
                            height: scaledHeight
                        )
                    }
                    
                    image.draw(in: drawRect)
                }
            } else {
                thumbnailImage = UIImage(systemName: "photo.fill")!
            }
        case .text:
            thumbnailImage = UIImage(systemName: "doc.text.fill")!
        }
        
        // Сохраняем в кеш
        ThumbnailCache.shared.setThumbnail(thumbnailImage, forKey: cacheKey)
        return thumbnailImage
    }
}
