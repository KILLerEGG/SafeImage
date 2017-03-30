//
//  DummyController.swift
//  SafeImage
//
//  Created by Graham Turbyne on 3/29/17.
//  Copyright © 2017 Graham Turbyne. All rights reserved.
//

import AVKit
import UIKit
import Agrume
import Photos
import Foundation
import AVFoundation
import MobileCoreServices
import DKImagePickerController

class DummyController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    var imagesDirectoryPath:String!
    var images:[UIImage]!
    var titles:[String]!
    var task:DispatchWorkItem!
    var player:AVPlayer!
    var playerController:AVPlayerViewController!
    var agrume:Agrume!
    var mediaCounter:Int!
    var isSwitchOn:Bool!
    var tempDeleteSwitch:UISwitch!
    var defaults:UserDefaults!
    var selectedCount:Int!
    
    var activityView: UIView!
    var activityIndicator:UIActivityIndicatorView!
    var activityText: UILabel!
    
    @IBOutlet weak var deleteSwitch: UIBarButtonItem!
    @IBOutlet weak var deleteSwitchLabel: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width
        let height = bounds.size.height
        
        activityView = UIView(frame: CGRect(x: (width/2)-160, y: (height/2)-100, width: 320, height: 50))
        activityView.backgroundColor = UIColor.lightGray
        activityView.layer.cornerRadius = 10
        activityView.isHidden = true
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.color = UIColor.darkGray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        //activityIndicator.frame = CGRect(x: (width/2)-45.0, y: (height/2)-150.0, width: 100.0, height:100.0)
        
        activityText = UILabel(frame: CGRect(x: 60, y: 0, width: 220, height: 50))
        activityText.text = "Downloading, please wait..."
        activityText.isHidden = true
        
        activityView.addSubview(activityIndicator)
        activityView.addSubview(activityText)
        
        //self.view.addSubview(activityIndicator)
        
        self.view.addSubview(activityView)
        
        self.selectedCount = 0
        
        // Init saved user setting for delete switch
        self.defaults = UserDefaults.standard
        
        // Ensure audio plays if a video is selected
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
     
        self.tableView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MainController.resetTimer(sender:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        self.tableView.addGestureRecognizer(tap)
        
        self.task = DispatchWorkItem {
            self.logout()
        }
        
        let tempDeleteSwitchLabel: UILabel = UILabel.init(frame: CGRect(x: 0.0, y: 0.0, width: 290.0, height: 20.0))
        tempDeleteSwitchLabel.text = "Delete from Photos after upload:"
        tempDeleteSwitchLabel.textColor = UIColor.white
        self.deleteSwitchLabel.customView = tempDeleteSwitchLabel
        
        isSwitchOn = false
        tempDeleteSwitch=UISwitch.init(frame: CGRect(x: 150.0, y: 300.0, width: 0.0, height: 0.0))
        tempDeleteSwitch.addTarget(self, action: #selector(DummyController.switchValueDidChange(sender:)), for: .valueChanged)
        
        self.deleteSwitch.customView = tempDeleteSwitch
        
        // Execute idle timeout in 5 minutes
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 300, execute: task)
        
        images = []
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        // Get the Document directory path
        let documentDirectorPath:String = paths[0]
        
        // Create a new path for the new images folder
        imagesDirectoryPath = documentDirectorPath.appending("/SafeImageDummy")
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: imagesDirectoryPath, isDirectory: &objcBool)
        
        // If the folder with the given path doesn't exist already, create it
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        }
        do{
            titles = try FileManager.default.contentsOfDirectory(atPath: imagesDirectoryPath)
            if titles.count > 0 {
                let lastTitle: String = titles[titles.count-1] as String
                let number = lastTitle.substring(to: lastTitle.index(lastTitle.startIndex, offsetBy: 5)) as NSString
                self.mediaCounter = Int(number as String)! + 1
            }
            else {
                self.mediaCounter = 1
            }
        }
        catch{
            self.mediaCounter = 1
        }
        self.refreshTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Get user saved user setting if it exists
        self.isSwitchOn = self.defaults.bool(forKey: "isOn")
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        // Set toolbar delete switch to saved user setting
        tempDeleteSwitch.setOn(isSwitchOn, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // Currently not used, keeping it just in case needed for future
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func switchValueDidChange(sender:UISwitch!)
    {
        if (sender.isOn == true){
            isSwitchOn = true
            self.defaults.set(true, forKey: "isOn") // Update saved user setting
        }
        else{
            isSwitchOn = false
            self.defaults.set(false, forKey: "isOn")
        }
    }
    
    func resetTimer(sender: UITapGestureRecognizer? = nil){
        // Reset the idle timeout
        self.task.cancel()
        
        self.task = DispatchWorkItem {
            self.logout()
        }
        // Execute idle timeout in 5 minutes
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 300, execute: task)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func logout(){
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func choosePhoto(_ sender: Any) {
        let pickerController = DKImagePickerController()
        pickerController.assetType = DKImagePickerControllerAssetType.allAssets
        pickerController.allowMultipleTypes = true
        pickerController.showsCancelButton = true
        
        var assetNum:Int! = self.mediaCounter
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM_dd_yyyy"
            let currentDate = NSDate()
            let convertedDateString = dateFormatter.string(from: currentDate as Date)
            if assets.count > 0{
                self.activityIndicator.startAnimating()
                self.activityText.isHidden = false
                self.activityView.isHidden = false
                self.view.addSubview(self.activityView)
            }
            var assetPaths = [String]()
            for _ in assets{
                assetPaths.insert(String(format: "%05d", assetNum), at: 0)
                assetNum = assetNum + 1
            }
            for asset in assets{
                if asset.isVideo{
                    let options: PHVideoRequestOptions = PHVideoRequestOptions()
                    options.version = .original
                    PHImageManager.default().requestAVAsset(forVideo: asset.originalAsset!, options: options, resultHandler: {(newAsset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                        
                        if let urlAsset = newAsset as? AVURLAsset {
                            let url:URL = urlAsset.url
                            let data = NSData(contentsOf: url)
                            var videoPath = (assetPaths.popLast()?.appending("-\(convertedDateString)"))!
                            videoPath = self.imagesDirectoryPath.appending("/\(videoPath).mp4")
                            data?.write(toFile: videoPath, atomically: false)
                            
                            if self.isSwitchOn! {
                                //Delete asset
                                let deleteAsset = NSArray(object: asset.originalAsset!)
                                PHPhotoLibrary.shared().performChanges( {
                                    PHAssetChangeRequest.deleteAssets(deleteAsset)
                                },
                                                                        completionHandler: { success, error in
                                                                            if error != nil{
                                                                                let ac = UIAlertController(title: "Error", message: "Video could not be deleted from your Photos", preferredStyle: .alert)
                                                                                self.present(ac, animated: true)
                                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                                                    ac.dismiss(animated: true, completion: nil)
                                                                                }
                                                                            }
                                                                            else{
                                                                                let ac = UIAlertController(title: "Success", message: "Video has been deleted from your Photos", preferredStyle: .alert)
                                                                                self.present(ac, animated: true)
                                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                                                    ac.dismiss(animated: true, completion: nil)
                                                                                }
                                                                            }
                                })
                            }
                            self.selectedCount = self.selectedCount + 1
                            if self.selectedCount == assets.count{
                                self.doneAdding()
                            }
                        }
                    })
                }
                else{
                    asset.fetchOriginalImageWithCompleteBlock({image, _ in
                        var imagePath = (assetPaths.popLast()?.appending("-\(convertedDateString)"))!
                        imagePath = self.imagesDirectoryPath.appending("/\(imagePath).jpeg")
                        let data = UIImageJPEGRepresentation(image!, 1.0)
                        _ = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
                        
                        if self.isSwitchOn! {
                            //Delete asset
                            let deleteAsset = NSArray(object: asset.originalAsset!)
                            PHPhotoLibrary.shared().performChanges( {
                                PHAssetChangeRequest.deleteAssets(deleteAsset)
                            },
                                                                    completionHandler: { success, error in
                                                                        if error != nil{
                                                                            let ac = UIAlertController(title: "Error", message: "Photo could not be deleted from your Photos", preferredStyle: .alert)
                                                                            self.present(ac, animated: true)
                                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                                                ac.dismiss(animated: true, completion: nil)
                                                                            }
                                                                        }
                                                                        else{
                                                                            let ac = UIAlertController(title: "Success", message: "Photo has been deleted from your Photos", preferredStyle: .alert)
                                                                            self.present(ac, animated: true)
                                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                                                ac.dismiss(animated: true, completion: nil)
                                                                            }
                                                                        }
                            })
                        }
                        self.selectedCount = self.selectedCount + 1
                        if self.selectedCount == assets.count{
                            self.doneAdding()
                        }
                    })
                }
            }
            self.mediaCounter = assetNum
        }
        
        self.present(pickerController, animated: true) {}
        
        // Original Code for single picker
        /*let imagePicker = UIImagePickerController()
         imagePicker.mediaTypes = ["public.image", "public.movie"]
         present(imagePicker, animated: true, completion: nil)
         imagePicker.delegate = self*/
    }
    
    func doneAdding(){
        self.activityIndicator.stopAnimating()
        self.activityText.isHidden = true
        self.activityView.isHidden = true
        self.activityView.removeFromSuperview()
        self.selectedCount = 0
        let size = self.titles.count-1
        self.refreshTable()
        DispatchQueue.main.async(execute: {
            self.scrollToBottom(animated: true, size: size)
        })
    }
    
    func refreshTable(){
        do{
            images.removeAll()
            
            titles = try FileManager.default.contentsOfDirectory(atPath: imagesDirectoryPath)
            
            for image in titles{
                let imageExt = image.substring(from:image.index(image.endIndex, offsetBy: -4)) as NSString
                if imageExt.isEqual(to: "jpeg"){ // Check if it's an image
                    let data = FileManager.default.contents(atPath: imagesDirectoryPath.appending("/\(image)"))
                    let image = UIImage(data: data!)
                    images.append(image!)
                }
                else { // Otherwise, it's a video
                    do {
                        // Try to generate a thumbnail image from first frame of the video for display
                        let fileURL = URL(fileURLWithPath: imagesDirectoryPath.appending("/\(image)"))
                        let asset = AVAsset(url: fileURL)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        let thumbnail = UIImage(cgImage: cgImage)
                        images.append(thumbnail)
                    } catch let error as NSError {
                        print("Error generating thumbnail: \(error)")
                    }
                }
            }
            self.tableView.reloadData()
        }catch{
            print("Error")
        }
    }
    
    func saveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            present(ac, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // in a second...
                // dismiss the popup
                ac.dismiss(animated: true, completion: nil)
            }
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Image has been saved to your Photos", preferredStyle: .alert)
            present(ac, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ac.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func saveVideo(_ videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            present(ac, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ac.dismiss(animated: true, completion: nil)
            }
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Video has been saved to your Photos", preferredStyle: .alert)
            present(ac, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ac.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func downloadFile(_ sender: UIButton){
        let index = sender.tag
        
        sender.backgroundColor = UIColor(red: 0.0, green:122.0/255.0, blue:1.0, alpha:1.0)
        
        if titles != nil{
            let path:String = titles[index]
            let data = FileManager.default.contents(atPath: imagesDirectoryPath.appending("/\(path)"))
            let imageExt = path.substring(from:path.index(path.endIndex, offsetBy: -4)) as NSString
            if imageExt.isEqual(to: "jpeg"){
                let image = UIImage(data: data!)
                // Save image back to camera roll
                UIImageWriteToSavedPhotosAlbum(image!, self, #selector(DummyController.saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
            }
            else {
                // Save video back to camera roll
                UISaveVideoAtPathToSavedPhotosAlbum(imagesDirectoryPath.appending("/\(path)"), self, #selector(DummyController.saveVideo(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    func resetDownloadButtonProps(_ sender: UIButton){
        sender.backgroundColor = UIColor.clear
    }
    
    func resetDeleteButtonProps(_ sender: UIButton){
        sender.backgroundColor = UIColor.clear
    }
    
    func deleteFile(_ sender: UIButton){
        let index = sender.tag
        
        sender.backgroundColor = UIColor(red: 214/255, green: 57/255, blue: 57/255, alpha: 1.0)
        
        if titles != nil {
            let path:String = titles[index]
            let fullPath = imagesDirectoryPath.appending("/\(path)")
            do{
                try FileManager.default.removeItem(atPath: fullPath)
                self.refreshTable()
            }
            catch{
                print("Could not remove file")
            }
        }
    }
    
    // Not needed now due to implementation of multi-file picker
    /*func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
     
     let size = titles.count
     
     let mediaType = info[UIImagePickerControllerMediaType] as! NSString
     
     let dateFormatter = DateFormatter()
     dateFormatter.dateFormat = "MM_dd_yyyy"
     let currentDate = NSDate()
     let convertedDateString = dateFormatter.string(from: currentDate as Date)
     
     if mediaType.isEqual(to: "public.image") {
     if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
     var imagePath = String(format: "%05d", self.mediaCounter)
     imagePath = imagePath.appending("-\(convertedDateString)")
     imagePath = imagesDirectoryPath.appending("/\(imagePath).jpeg")
     let data = UIImageJPEGRepresentation(image, 1.0)
     _ = FileManager.default.createFile(atPath: imagePath, contents: data, attributes: nil)
     self.mediaCounter = self.mediaCounter + 1
     }
     else{
     print("Something went wrong")
     }
     }
     else if mediaType.isEqual(to: "public.movie") {
     if let url = info[UIImagePickerControllerMediaURL] as? URL {
     let data = NSData(contentsOf: url)
     var videoPath = String(format: "%05d", self.mediaCounter)
     videoPath = videoPath.appending("-\(convertedDateString)")
     videoPath = imagesDirectoryPath.appending("/\(videoPath).mp4")
     data?.write(toFile: videoPath, atomically: false)
     self.mediaCounter = self.mediaCounter + 1
     }
     else{
     print("Something went wrong")
     }
     }
     
     if self.isSwitchOn! {
     let imageUrl = info[UIImagePickerControllerReferenceURL] as! NSURL
     let imageUrls = [imageUrl]
     
     //Delete asset
     PHPhotoLibrary.shared().performChanges( {
     let imageAssetsToDelete = PHAsset.fetchAssets(withALAssetURLs: imageUrls as [URL], options: nil)
     PHAssetChangeRequest.deleteAssets(imageAssetsToDelete)
     },
     completionHandler: { success, error in
     var message:String!
     if error != nil{
     if mediaType.isEqual(to: "public.image"){
     message = "Image could not be deleted from your Photos"
     }
     else{
     message = "Video could not be deleted from your Photos"
     }
     let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
     self.present(ac, animated: true)
     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
     ac.dismiss(animated: true, completion: nil)
     }
     }
     else{
     if mediaType.isEqual(to: "public.image"){
     message = "Image has been deleted from your Photos"
     }
     else{
     message = "Video has been deleted from your Photos"
     }
     let ac = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
     self.present(ac, animated: true)
     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
     ac.dismiss(animated: true, completion: nil)
     }
     }
     })
     }
     
     self.dismiss(animated: true) { () -> Void in
     self.refreshTable()
     
     DispatchQueue.main.async(execute: {
     self.scrollToBottom(animated: true, size: size)
     })
     }
     }*/
    
    func scrollToBottom(animated:Bool, size:Int) {
        let indexPath = NSIndexPath.init(row: self.titles.count-1, section: 0)
        
        self.tableView.scrollToRow(at: indexPath as IndexPath, at: .bottom, animated: animated)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "CellID")
        
        // Init download button and set attributes
        let downloadButton = UIButton(type: .custom)
        downloadButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        downloadButton.layer.cornerRadius = 5
        downloadButton.layer.borderWidth = 1
        downloadButton.layer.borderColor = UIColor(red: 0.0, green:122.0/255.0, blue:1.0, alpha:1.0).cgColor
        downloadButton.backgroundColor = UIColor.clear
        downloadButton.setTitle("U", for: .normal)
        downloadButton.setTitleColor(UIColor(red: 0.0, green:122.0/255.0, blue:1.0, alpha:1.0), for: .normal)
        downloadButton.setTitleColor(UIColor.clear, for: .selected)
        downloadButton.setTitleColor(UIColor.clear, for: .highlighted)
        downloadButton.addTarget(self, action: #selector(DummyController.downloadFile(_:)), for: .touchDown)
        downloadButton.addTarget(self, action: #selector(DummyController.resetDownloadButtonProps(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(DummyController.resetDownloadButtonProps(_:)), for: .touchUpOutside)
        downloadButton.tag = indexPath.row
        
        // Init delete button and set attributes
        let deleteButton = UIButton(type: .custom)
        deleteButton.frame = CGRect(x: 40, y: 0, width: 30, height: 30)
        deleteButton.layer.cornerRadius = 5
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor(red: 214/255, green: 57/255, blue: 57/255, alpha: 1.0).cgColor
        deleteButton.backgroundColor = UIColor.clear
        deleteButton.setTitle("X", for: .normal)
        deleteButton.setTitleColor(UIColor(red: 214/255, green: 57/255, blue: 57/255, alpha: 1.0), for: .normal)
        deleteButton.setTitleColor(UIColor.clear, for: .selected)
        deleteButton.setTitleColor(UIColor.clear, for: .highlighted)
        deleteButton.addTarget(self, action: #selector(DummyController.deleteFile(_:)), for: .touchDown)
        deleteButton.addTarget(self, action: #selector(DummyController.resetDeleteButtonProps(_:)), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(DummyController.resetDeleteButtonProps(_:)), for: .touchUpOutside)
        deleteButton.tag = indexPath.row
        
        // Add custom buttons to UIView for cell's accessory view
        let buttons: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        buttons.addSubview(downloadButton)
        buttons.addSubview(deleteButton)
        
        // Setup cell view
        cell?.accessoryView = buttons
        cell?.imageView?.image = images[indexPath.row]
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if images != nil {
            // Init Agrume 3rd party image viewer class
            self.agrume = Agrume(images: self.images, startIndex: indexPath.row, backgroundBlurStyle: .dark)
            self.agrume.didScroll = { [unowned self] index in
                self.tableView.scrollToRow(at: IndexPath.init(row: index, section: 0), at: UITableViewScrollPosition.none, animated: false)
            }
            let fileName = tableView.cellForRow(at: indexPath)?.textLabel?.text as String!
            let imageExt = fileName!.substring(from:(fileName!.index(fileName!.endIndex, offsetBy: -4))) as String! as NSString
            if imageExt.isEqual(to: "jpeg"){
                // If it's an image, open the image with Agrume
                agrume.showFrom(self)
            }
            else{
                // If it's a video, instantiate and open media with AVPlayer
                let filePathURL = URL(fileURLWithPath: self.imagesDirectoryPath.appending("/\(fileName!)"))
                self.player = AVPlayer(url: filePathURL)
                self.playerController = AVPlayerViewController()
                self.playerController.player = player
                self.present(playerController, animated: true) {
                    self.player.play()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
}

