//
//  AuthenticationController.swift
//  SafeImage
//
//  Created by Graham Turbyne on 12/24/16.
//  Copyright © 2016 Graham Turbyne. All rights reserved.
//

import UIKit
import Foundation
import LocalAuthentication

class AuthenticationController: UIViewController, UITextFieldDelegate {
    
    var originalOrientation:NSString = "portrait"
    
    let MyKeychainWrapper = KeychainWrapper()
    let createLoginButtonTag = 0
    let loginButtonTag = 1
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var touchIDButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var createInfoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.darkGray
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let hasLogin = UserDefaults.standard.bool(forKey: "hasLoginKey")
        
        loginButton.layer.cornerRadius = 5
        
        if hasLogin {
            loginButton.setTitle("Login", for: UIControlState.normal)
            loginButton.tag = loginButtonTag
            createInfoLabel.text = "Enter your password to log in"
        } else {
            loginButton.setTitle("Create", for: UIControlState.normal)
            loginButton.tag = createLoginButtonTag
        }
        
        self.passwordTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AuthenticationController.dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.touchAuth()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if (checkLogin(password: textField.text!)) {
            self.navigateToAuthenticatedViewController()
        }
        else {
            showAlertWithTitle(title: "Error", message: "Invalid password")
        }
        return true
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func checkLogin(password: String ) -> Bool {
        if password == MyKeychainWrapper.myObject(forKey: "v_Data") as? String {
            return true
        } else {
            return false
        }
    }
    
    
    func touchAuth(){
        let authenticationContext = LAContext()
        
        var error:NSError?
        
        // 2. Check if the device has a fingerprint sensor
        guard authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        else {
            touchIDButton.isHidden = true
            return
        }
        
        // 3. Check the fingerprint
        authenticationContext.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to view photos",
            reply: { [unowned self] (success, error) -> Void in
                
                if( success ) {
                    
                    // Fingerprint recognized
                    // Go to view controller
                    self.dismissKeyboard()
                    self.navigateToAuthenticatedViewController()
                    
                }
        })
    }
    
    func navigateToAuthenticatedViewController(){
        if let loggedInVC = storyboard?.instantiateViewController(withIdentifier: "MainController") {
            
            DispatchQueue.main.async { () -> Void in
                self.passwordTextField.text = ""
                self.dismissKeyboard()
                self.navigationController?.pushViewController(loggedInVC, animated: true)
            }
            
        }
        
    }
    
    func errorMessageForLAErrorCode( errorCode:Int ) -> String{
        
        var message = ""
        
        switch errorCode {
            
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
            
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
            
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
            
        case LAError.touchIDLockout.rawValue:
            message = "Too many failed attempts."
            
        case LAError.touchIDNotAvailable.rawValue:
            message = "TouchID is not available on the device"
            
        case LAError.userCancel.rawValue:
            message = "The user did cancel"
            
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
            
        default:
            message = "Did not find error code on LAError object"
            
        }
        
        return message
        
    }
    
    func showAlertViewIfNoBiometricSensorHasBeenDetected(){
        showAlertWithTitle(title: "Error", message: "This device does not have a TouchID sensor.")
    }
    
    func showAlertWithTitle( title:String, message:String ) {
        
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertVC.addAction(okAction)
        
        DispatchQueue.main.async { () -> Void in
            self.present(alertVC, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func authenticateButton(_ sender: Any) {
        
        if (sender as AnyObject).tag == createLoginButtonTag {
            if self.passwordTextField.text != "" {
                MyKeychainWrapper.mySetObject(passwordTextField.text, forKey:kSecValueData)
                MyKeychainWrapper.writeToKeychain()
                UserDefaults.standard.set(true, forKey: "hasLoginKey")
                UserDefaults.standard.synchronize()
                loginButton.tag = loginButtonTag
                loginButton.setTitle("Login", for: UIControlState.normal)
                createInfoLabel.text = "Enter your password to log in"
                
                self.dismissKeyboard()
                self.navigateToAuthenticatedViewController()
            }
            else {
                showAlertWithTitle(title: "Error", message: "Password cannot be blank")
            }
        }
        else if (sender as AnyObject).tag == loginButtonTag {
            self.passwordTextField.resignFirstResponder()
            if (checkLogin(password: passwordTextField.text!)) {
                self.navigateToAuthenticatedViewController()
            }
            else {
                showAlertWithTitle(title: "Error", message: "Invalid password")
            }
        }
    }
    
    @IBAction func touchLogin(_ sender: Any) {
        self.dismissKeyboard()
        self.touchAuth()
    }
    
    func adjustViewsForOrientation(toInterfaceOrientation: UIInterfaceOrientation){
        // Move buttons on screen to line up horizontally if and only if switching to landscape from portrait
        if (toInterfaceOrientation == UIInterfaceOrientation.landscapeLeft || toInterfaceOrientation == UIInterfaceOrientation.landscapeRight) && !(self.originalOrientation.isEqual(to: "landscape")){
            let bounds = UIScreen.main.bounds
            let width = bounds.size.width
            if touchIDButton.isHidden {
                self.loginButton.frame = CGRect(x: (width-124)/2, y: 440.0, width: 124, height: 57)
            }
            else {
                self.loginButton.frame = CGRect(x: (width-124)*0.25, y: 440.0, width: 124, height: 57)
                self.touchIDButton.frame = CGRect(x: (width-67)*0.75, y: 440.0, width: 67, height: 66)
            }
            self.originalOrientation = "landscape"
        }
        // Move buttons on screen to line up vertically if switching to portrait from landscape
        else if (toInterfaceOrientation == UIInterfaceOrientation.portrait) {
            let bounds = UIScreen.main.bounds
            let width = bounds.size.width
            self.loginButton.frame = CGRect(x: (width-124)/2, y: 130.0, width: 124, height: 57)
            if !(touchIDButton.isHidden) {
                self.touchIDButton.frame = CGRect(x: (width-67)/2, y: 175.0, width: 67, height: 66)
            }
            self.originalOrientation = "portrait"
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.adjustViewsForOrientation(toInterfaceOrientation: toInterfaceOrientation)
    }

}
