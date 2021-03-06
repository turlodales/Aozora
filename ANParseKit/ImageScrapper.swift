//
//  MALScrapper.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit

public class ImageData {
    
    public var url: String
    public var width: Int
    public var height: Int
    
    init(url: String, width: Int, height: Int) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    class func imageDataWithDictionary(dictionary: [String: AnyObject]) -> ImageData {
        return ImageData(
            url: dictionary["url"] as! String,
            width: dictionary["width"] as! Int,
            height: dictionary["height"] as! Int)
    }
    
    public func toDictionary() -> [String: AnyObject] {
        return ["url": url, "width": width, "height": height]
    }
}

public class ImageScrapper {
    
    var viewController: UIViewController
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    public func findImagesWithQuery(string: String, animated: Bool) -> BFTask {
        let baseURL = "https://www.google.com/search"
        let queryURL = "?q=\(string)&tbm=isch&safe=active&tbs=isz:m" + (animated ? ",itp:animated" : "")
        let encodedRequest = baseURL + queryURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        let completion = BFTaskCompletionSource()
        
        viewController.webScraper.scrape(encodedRequest) { (hpple) -> Void in
            if hpple == nil {
                print("hpple is nil")
                completion.setError(NSError(domain: "aozora", code: 0, userInfo: nil))
                return
            }
            
            let results = hpple.searchWithXPathQuery("//div[@id='rg_s']/div/a") as! [TFHppleElement]
            var images: [ImageData] = []
            
            for result in results {
                
                let urlString = result.objectForKey("href")
                if let url = NSURL(string: urlString),
                    let parameters = BFURL(URL: url).inputQueryParameters,
                    let imageURL = parameters["imgurl"] as? String,
                    let sizeRaw = result.hppleElementFor(path: [1,0,0,0])?.content {
                        
                        let values = sizeRaw.componentsSeparatedByString(" ")[1]
                        let valuesFiltered = values.componentsSeparatedByString(" × ")
                        let width = Int(valuesFiltered[0])!
                        let height = Int(valuesFiltered[1])!
                        
                        if width <= 1400 && height <= 1400 {
                            if animated && imageURL.endsWith(".gif") {
                                let imageData = ImageData(url: imageURL, width: width, height: height)
                                images.append(imageData)
                            } else if !animated && (imageURL.endsWith(".jpg") || imageURL.endsWith(".jpeg") || imageURL.endsWith(".png")) {
                                let imageData = ImageData(url: imageURL, width: width, height: height)
                                images.append(imageData)
                            }
                        }
                }
            }
            
            print("found \(images.count) images")
            completion.setResult(images)
        }
        
        return completion.task
    }
}

