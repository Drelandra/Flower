//
//  FlowerData.swift
//  Flower
//
//  Created by Andre Elandra on 27/07/20.
//  Copyright © 2020 Andre Elandra. All rights reserved.
//

import Foundation

struct FlowerData: Codable {
    let batchcomplete: String
    let query: Query
}

struct Query: Codable {
    let pageids: [String]
    let pages: [String : Pages]
}

struct Pages: Codable {
//    let pageid, ns: Int
    let title, extract: String
    let thumbnail: Thumbnail
}

struct Thumbnail: Codable {
    let source: String
}

