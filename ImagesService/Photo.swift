//
//  Photo.swift
//  ImageFeed
//
//  Created by Sofia Noelle on 12.06.26.
//

import Foundation
import CoreGraphics

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}
