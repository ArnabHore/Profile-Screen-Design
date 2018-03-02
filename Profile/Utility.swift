//
//  Utility.swift
//  Profile
//
//  Created by arnab on 02/03/18.
//  Copyright © 2018 arnab. All rights reserved.
//

import UIKit

class Utility: NSObject {

    public func reachable() -> Bool {
        let reachable = Reachability(hostName: "apple.com")
        let internetStatus: NetworkStatus = reachable!.currentReachabilityStatus()
        if internetStatus == NotReachable {
            return false
        }
        return true
    }
    
    public func getUrl(api: NSString) -> NSString {
        let base = "https://example-test.com/"
        var urlString: NSString!
        
        if api.caseInsensitiveCompare("profile") == .orderedSame {
            urlString = NSString(format: "%@%@", base,"profile/")
        }
        
        return urlString
    }
    
    func uploadImage(withFileName fileName: String, withapi api: NSString, append appendString: NSString, jsonDict: NSDictionary, forAction action: NSString, onController currentController: UIViewController, completion:@escaping (NSDictionary!) -> ()) {
        var outputFileURL: URL?
        let urlString: NSString = "\(getUrl(api: api))\(appendString)" as NSString
        if !fileName.isEmpty {
            let pathComponents = [NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!, fileName]
            outputFileURL = NSURL.fileURL(withPathComponents: pathComponents)
        }
        // create request
        let request = NSMutableURLRequest()
        request.url = URL(string: urlString as String)
        request.httpMethod = action as String
        
        var body = Data()
        let boundary = "\(NSUUID().uuidString)"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue("image/*", forHTTPHeaderField: "Media-Type")
        
        if !fileName.isEmpty {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpeg\"\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Type: image/*\r\n\r\n".data(using: String.Encoding.utf8)!)
            do {
                try body.append(Data(contentsOf: outputFileURL!))
            } catch {
                print(error)
            }
            body.append("\r\n".data(using: String.Encoding.utf8)!)
            body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        }
        //json data
        
        if jsonDict.count > 0 {
            for (key, value) in jsonDict {
                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
            }
        }
        
        //end
        
        // setting the body of the post to the reqeust
        request.httpBody = body

        var json: NSDictionary!
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data,response,error in
            if error != nil{
                print((error?.localizedDescription)! as String)
                completion([String: String]() as NSDictionary)
            }
            
            do {
                if data != nil {
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if json != nil {
                        completion(json)
                    } else {
                        completion([String: String]() as NSDictionary)
                    }
                }
            } catch let error as NSError {
                print(error)
                completion([String: String]() as NSDictionary)
            }
        }
        task.resume()
    }
    
    public func showAlert(title: String, message: String, controller: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
