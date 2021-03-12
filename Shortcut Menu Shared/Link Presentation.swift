//
//  Rich Links.swift
//  Wots4T
//
//  Created by Marc Shearer on 04/02/2021.
//

import LinkPresentation
import UniformTypeIdentifiers
import SwiftUI

class LinkPresentation {
    
    static func getDetail(url: URL, getImage: Bool = false, completion: @escaping (Result<(image: MyImage?, title: String?), Error>)->()) {
        
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let metadata = metadata {
                    if getImage {
                        if let imageProvider = metadata.imageProvider {
                            imageProvider.loadItem(forTypeIdentifier: UTType.image.identifier) { (image, error) in
                                if let error = error {
                                    completion(.failure(error))
                                } else {
                                    completion(.success((image: image as? MyImage ?? MyImage(), title: metadata.title)))
                                }
                            }
                        } else {
                            completion(.failure(LinkPresentationError.noImageProvider))
                        }
                    } else {
                        completion(.success((image: nil, title: metadata.title)))
                    }
                } else {
                    completion(.failure(LinkPresentationError.noMetadata))
                }
            }
        }
    }
}

enum LinkPresentationError: Error {
    case noMetadata
    case noImageProvider
}

#if canImport(UIKit)
struct LinkView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    var metadata: LPLinkMetadata?
    var frame: CGRect
    
    func makeUIView(context: Context) -> UIView {
        let imageView = UIImageView(frame: frame)
        
        if let metadata = metadata, let imageProvider = metadata.imageProvider {
            imageProvider.loadObject(ofClass: MyImage.self) { (image, error) in
                if error == nil {
                    if let image = image as? MyImage {
                        imageView.image = image
                    }
                }
            }
        }
        return imageView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
#endif
