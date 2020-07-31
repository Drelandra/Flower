//
//  FlowerManager.swift
//  Flower
//
//  Created by Andre Elandra on 27/07/20.
//  Copyright © 2020 Andre Elandra. All rights reserved.
//

import Foundation
import UIKit

protocol FlowerManagerDelegate {
    func didFailWithError(_ error: Error)
    func didUpdateFlower(_ flowerManager: FlowerManager, _ flowerModel: FlowerModel)
}

struct FlowerManager {
    
    var delegate: FlowerManagerDelegate?
    
    func fetchFlower(flowerName: String){
        let flowerUrl = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts|pageimages&exintro=&explaintext=&titles=\(flowerName)&indexpageids=&redirects=1&pithumbsize=500"
        
        guard let flowerUrlQuery = flowerUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { fatalError("Failed to modify url") }
        
        performRequest(with: flowerUrlQuery)
    }
    
    func performRequest(with urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error!)
                    return
                }
                if let safeData = data {
                    if let flower = self.parseJSON(safeData) {
                        
                        self.delegate?.didUpdateFlower(self, flower)
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ flowerData: Data) -> FlowerModel? {
        let decoder = JSONDecoder()
        do{
            let decodedData = try decoder.decode(FlowerData.self, from: flowerData)
            
            guard
                let pageID = decodedData.query.pageids.first,
                let title = decodedData.query.pages[pageID]?.title,
                let extract = decodedData.query.pages[pageID]?.extract,
                let flowerImageUrl = decodedData.query.pages[pageID]?.thumbnail.source
                else { fatalError("can't decode the JSON data") }
        
            let flower = FlowerModel(title: title, desc: extract, flowerImageURL: flowerImageUrl)
            return flower
            
        }catch {
            self.delegate?.didFailWithError(error)
            return nil
        }
    }
    
}

//extension String {
//    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")
//
//    public func convertedToSlug() -> String? {
//        if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) {
//            let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
//            let result = urlComponents.filter { $0 != "" }.joined(separator: "-")
//
//            if result.count > 0 {
//                return result
//            }
//        }
//
//        return nil
//    }
//}
