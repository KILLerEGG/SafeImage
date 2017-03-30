//
//  ChangePassController.swift
//  SafeImage
//
//  Created by Graham Turbyne on 3/29/17.
//  Copyright © 2017 Graham Turbyne. All rights reserved.
//

import UIKit
import Foundation
import LocalAuthentication

class ChangePassController: UIViewController, UITextFieldDelegate {
    
    var originalOrientation:NSString = "portrait"
    
    @IBOutlet weak var passwordTextField: UITextField!
    let MyKeychainWrapper = KeychainWrapper()
    
    @IBOutlet weak var changePassButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.passwordTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AuthenticationController.dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func showAlertWithTitle( title:String, message:String ) {
        
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertVC.addAction(okAction)
        
        DispatchQueue.main.async { () -> Void in
            self.present(alertVC, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func changePassAction(_ sender: Any) {
        if self.passwordTextField.text != "" {
            MyKeychainWrapper.mySetObject(passwordTextField.text, forKey:kSecValueData)
            MyKeychainWrapper.writeToKeychain()
            UserDefaults.standard.set(true, forKey: "hasLoginKey")
            UserDefaults.standard.synchronize()
            
            self.dismissKeyboard()
            
            _ = navigationController?.popViewController(animated: true)
        }
        else {
            showAlertWithTitle(title: "Error", message: "Password cannot be blank")
        }
    }
    
    func adjustViewsForOrientation(toInterfaceOrientation: UIInterfaceOrientation){
        // Move buttons on screen to line up horizontally if and only if switching to landscape from portrait
        if (toInterfaceOrientation == UIInterfaceOrientation.landscapeLeft || toInterfaceOrientation == UIInterfaceOrientation.landscapeRight) && !(self.originalOrientation.isEqual(to: "landscape")){
            let bounds = UIScreen.main.bounds
            let width = bounds.size.width
            self.changePassButton.frame = CGRect(x: (width-124)/2, y: 440.0, width: 124, height: 57)
            self.originalOrientation = "landscape"
        }
        // Move buttons on screen to line up vertically if switching to portrait from landscape
        else if (toInterfaceOrientation == UIInterfaceOrientation.portrait) {
            let bounds = UIScreen.main.bounds
            let width = bounds.size.width
            self.changePassButton.frame = CGRect(x: (width-124)/2, y: 130.0, width: 124, height: 57)
            self.originalOrientation = "portrait"
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.adjustViewsForOrientation(toInterfaceOrientation: toInterfaceOrientation)
    }
}
