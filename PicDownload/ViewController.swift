//
//  ViewController.swift
//  PicDownload
//
//  Created by 龘天 on 2022/1/29.
//

import UIKit
import Kanna

class ViewController: UIViewController, URLSessionDownloadDelegate {
    
    @IBOutlet weak var myImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gengo = 285087
        let honUrl = "https://nhentai.net/g/" + String(gengo)
        let honPath = NSHomeDirectory() + "/Documents/" + String(gengo)
        print(honPath)
        do {
            try FileManager.default.createDirectory(atPath: honPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Cannot create directory")
        }
        print("debug1")
        let url = URL(string: honUrl)
        var pages = "1"
        do{
            //取得送出後資料的回傳值
            let html = try String(contentsOf: url!)
            let doc = try HTML(html: html, encoding: .utf8)
            let pagesXpath = doc.xpath("//*[@id='tags']/div[@class='tag-container field-name']/span/a/span")
            pages = (pagesXpath.first?.text)!
            print("pages: " + pages)
        } catch {
            print(error)
        }
        
        print("debug2")
        for index in 1...Int(pages)! {
            let pageUrl = honUrl + "/\(index)"
            do{
                //取得送出後資料的回傳值
                let pageHtml = try String(contentsOf: URL(string: pageUrl)!)
                let doc = try HTML(html: pageHtml, encoding: .utf8)
                let imageXpath = doc.xpath("//*[@id='image-container']/a/img")
                let imageUrl = imageXpath.first?["src"]
                print("image link: " + imageUrl!)
                downloadImage(page: String(index), imageUrl: imageUrl!, gengo: String(gengo))
            } catch {
                print(error)
            }
        }
        print("debug3")
        
        lazy var applicationSupportURL: URL = {
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                return urls[0]
        }()
        var isDir: ObjCBool = true
        if !FileManager.default.fileExists(atPath: applicationSupportURL.path, isDirectory: &isDir) {
                do {
                    try FileManager.default.createDirectory(atPath: applicationSupportURL.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error)
                }
        }

    }
    
    func downloadImage(page: String, imageUrl: String, gengo: String) {
        let url = URL(string: imageUrl)
        //使用者背景設定建立 session，並且給一個 session 的名字
        let gengoAndPage = gengo + "/" + page
        let config = URLSessionConfiguration.background(withIdentifier: gengoAndPage)
        print()
        // delegateQueue 如果為 nil，delegate 會在另外一個執行緒中被呼叫
        let session = URLSession(configuration: config, delegate: self,delegateQueue: nil)
        let dnTask = session.downloadTask(with: url!)
        dnTask.resume()
        print("downloding " + page)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let identifier = session.configuration.identifier!
        let folder = identifier.components(separatedBy:"/")[0]
        print("folder: " + folder)
        let fileName = downloadTask.originalRequest?.url?.lastPathComponent
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        var destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appending("/" + folder))
        do {
            try fileManager.createDirectory(at: destinationURLForFile, withIntermediateDirectories: true, attributes: nil)
            destinationURLForFile.appendPathComponent(String(describing: fileName!))
            try fileManager.moveItem(at: location, to: destinationURLForFile)
        }catch(let error){
            print(error)
        }
    }
    
    func saveImage(currentImage: UIImage, persent: CGFloat, path: String, index: Int){
        if let imageData = currentImage.jpegData(compressionQuality: persent) as NSData? {
            let fullPath = path + "/\(index)"
            imageData.write(toFile: fullPath, atomically: true)
            print("fullPath=\(fullPath)")
        }
    }
}

