//
//  My Image.swift
//  Wots4T
//
//  Created by Marc Shearer on 26/02/2021.
//

import SwiftUI

#if canImport(UIKit)

typealias MyImage = UIImage

#else

typealias MyImage = NSImage

extension NSImage {
    func pngData() -> Data? {
        return { self.tiffRepresentation?.bitmap?.png }()
    }
}

#endif

#if canImport(UIKit)
#else
extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
#endif

extension Image {
    #if canImport(UIKit)
    init(myImage: MyImage) {
        self.init(uiImage: myImage)
    }
    #else
    init(myImage: MyImage) {
        self.init(nsImage: myImage)
    }
    #endif
}
