//
//  ImageSource.swift
//  Silica
//
//  Created by Alsey Coleman Miller on 6/1/17.
//
//

import struct Foundation.Data

/// This object abstracts the data-reading task. 
/// An image source can read image data from a `Data` instance.
public protocol CGImageSource: AnyObject, RandomAccessCollection {
    
    associatedtype Index = Int
    associatedtype Indices = DefaultIndices<Self>
    associatedtype Iterator = IndexingIterator<Self>
    
    static var typeIdentifier: String { get }
        
    init?(data: Data)
        
    func createImage(at index: Int) -> CGImage?
}

public extension CGImageSource {
    
    var count: Int { return 1 } // only some formats like GIF have multiple images
    
    subscript (index: Int) -> CGImage {
        
        guard let image = createImage(at: index)
            else { fatalError("No image at index \(index)") }
        
        return image
    }
    
    subscript(bounds: Range<Self.Index>) -> Slice<Self> {
        
        return Slice<Self>(base: self, bounds: bounds)
    }
    
    /// The start `Index`.
    var startIndex: Int {
        
        return 0
    }
    
    /// The end `Index`.
    ///
    /// This is the "one-past-the-end" position, and will always be equal to the `count`.
    var endIndex: Int {
        return count
    }
    
    func index(before i: Int) -> Int {
        return i - 1
    }
    
    func index(after i: Int) -> Int {
        return i + 1
    }
    
    func makeIterator() -> IndexingIterator<Self> {
        
        return IndexingIterator(_elements: self)
    }
}

// MARK: - CoreGraphics

public enum CGImageSourceOption: String {
    
    case typeIdentifierHint = "kCGImageSourceTypeIdentifierHint"
    case shouldAllowFloat = "kCGImageSourceShouldAllowFloat"
    case shouldCache = "kCGImageSourceShouldCache"
    case createThumbnailFromImageIfAbsent = "kCGImageSourceCreateThumbnailFromImageIfAbsent"
    case createThumbnailFromImageAlways = "kCGImageSourceCreateThumbnailFromImageAlways"
    case createThumbnailWithTransform = "kCGImageSourceCreateThumbnailWithTransform"
    case thumbnailMaxPixelSize = "kCGImageSourceThumbnailMaxPixelSize"
}

public func CGImageSourceCreateWithData(_ data: Data, _ options: [CGImageSourceOption: Any]?) {
    
    
}

@inline(__always)
public func CGImageSourceGetType<T: CGImageSource>(_ imageSource: T) -> String {
    
    return T.typeIdentifier
}

public func CGImageSourceCopyTypeIdentifiers() -> [String] {
    
    return [CGImageSourcePNG.typeIdentifier]
}
