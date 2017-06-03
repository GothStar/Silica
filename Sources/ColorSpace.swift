//
//  ColorSpace.swift
//  Silica
//
//  Created by Alsey Coleman Miller on 6/2/17.
//
//

import struct Foundation.Data
import CLCMS

/// A profile that specifies how to interpret a color value for display.
public final class ColorSpace {
    
    // MARK: - Properties
    
    /// ICC profile data for color spaces created from ICC profiles.
    public let data: Data?
    
    fileprivate let profile: cmsHPROFILE
    
    // MARK: - Initialization
    
    deinit {
        
        // deallocate profile
        cmsCloseProfile(profile)
    }
    
    fileprivate init(profile: cmsHPROFILE) {
        
        self.profile = profile
        self.data = nil
    }
    
    public init?(file: String, access: FileAccess) {
        
        guard let profile = cmsOpenProfileFromFile(file, access.rawValue)
            else { return nil }
        
        self.profile = profile
        self.data = nil
    }
    
    public init?(data: Data) {
        
        guard let profile = data.withUnsafeBytes({ cmsOpenProfileFromMem($0, cmsUInt32Number(data.count)) })
            else { return nil }
        
        self.profile = profile
        self.data = data
    }
    
    public init(gray: (white: (Double, Double, Double), black: (Double, Double, Double)), gamma: Double) {
        
        var whiteCIExyY = cmsCIExyY(CIEXYZ: gray.white)
        
        let table = cmsBuildGamma(nil, gamma)
        
        defer { cmsFreeToneCurve(table) }
        
        guard let profile = cmsCreateGrayProfile(&whiteCIExyY, table)
            else { fatalError("Could not create calibrated grey color space") }
        
        self.profile = profile
        self.data = nil
    }
    
    // MARK: - Accessors
    
    public var name: String? {
        
        // FIXME: Is this correct?
        return profileInfo(.description)
    }
    
    public var numberOfComponents: UInt {
        
        return UInt(cmsChannelsOf(cmsGetColorSpace(profile)))
    }
    
    // MARK: - Methods
    
    public func profileInfo(_ infoType: ProfileInfo, for locale: (languageCode: String, countryCode: String) = (cmsNoLanguage, cmsNoCountry)) -> String? {
        
        let info = cmsInfoType(infoType)
        
        // get buffer size
        let bufferSize = cmsGetProfileInfo(profile, info, locale.languageCode, locale.countryCode, nil, 0)
        
        guard bufferSize > 0 else { return nil }
        
        // allocate buffer and get data
        var data = Data(repeating: 0, count: Int(bufferSize))
        
        guard data.withUnsafeMutableBytes({ cmsGetProfileInfo(profile, info, locale.languageCode, locale.countryCode, UnsafeMutablePointer<wchar_t>($0), bufferSize) }) != 0 else { fatalError("Cannot get data for \(infoType)") }
        
        assert(wchar_t.self == Int32.self, "wchar_t is \(wchar_t.self)")
        
        // try to decode data into string
        let possibleEncodings: [String.Encoding] = [.utf32, .utf32LittleEndian, .utf32BigEndian]
        
        for encoding in possibleEncodings {
            
            guard let string = String(data: data, encoding: encoding)
                else { continue }
            
            return string
        }
        
        return nil
    }
}

// MARK: - Equatable

extension ColorSpace: Equatable {
    
    public static func == (lhs: ColorSpace, rhs: ColorSpace) -> Bool {
        
        // FIXME
        return lhs.profile == rhs.profile
    }
}

// MARK: - Singletons

public extension ColorSpace {
    
    /// Grayscale color space with gamma 2.2 and a D65 white point.
    static let genericRGB: ColorSpace = ColorSpace(gray: ((0.9504, 1.0000, 1.0888), (0,0,0)), gamma: 2.2)
    
    static let genericGray: ColorSpace = ColorSpace(profile: cmsCreate_sRGBProfile()) // fixme
}

// MARK: - Supporting Types

public extension ColorSpace {
    
    public enum ProfileInfo {
        
        case description
        case manufacturer
        case model
        case copyright
    }
    
    public enum FileAccess: String {
        
        case read = "r"
        case write = "w"
    }
    
    /// Models for color spaces.
    public enum Model {
        
        /// An unknown color space model.
        case unknown
        
        /// A monochrome color space model.
        case monochrome
        
        /// An RGB color space model.
        case rgb
        
        /// A CMYK color space model.
        case cmyk
        
        /// A Lab color space model.
        case lab
        
        /// A DeviceN color space model.
        case deviceN
        
        /// An indexed color space model.
        case indexed
        
        /// A pattern color space model.
        case pattern
    }
}

// MARK: - Little CMS Extensions / Helpers

extension cmsInfoType {
    
    init(_ info: ColorSpace.ProfileInfo) {
        
        switch info {
        case .description:  self = cmsInfoDescription
        case .manufacturer: self = cmsInfoManufacturer
        case .model:        self = cmsInfoModel
        case .copyright:    self = cmsInfoCopyright
        }
    }
}

extension cmsCIExyY {
    
    init(CIExyz point: (Double, Double, Double)) {
        
        self.init(x: point.0, y: point.1, Y: 1)
    }
    
    init(CIEXYZ point: (Double, Double, Double)) {
        
        var XYZ = cmsCIEXYZ(X: point.0, Y: point.1, Z: point.2)
        
        self.init()
        
        cmsXYZ2xyY(&self, &XYZ)
    }
}
