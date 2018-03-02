//
//  ViewController.swift
//  Profile
//
//  Created by arnab on 01/03/18.
//  Copyright © 2018 arnab. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var mainScroll: UIScrollView!

    var activeTextField: UITextField!
    var selectedImage: UIImage!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let numberToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        numberToolbar.barStyle = UIBarStyle.default
        numberToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneWithNumberPad))]
        numberToolbar.sizeToFit()
        phoneTextField.inputAccessoryView = numberToolbar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        self.bottomView.addTopRoundedCornerToView(targetView: self.bottomView, desiredCurve: 0.6)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.topView.bounds
        gradientLayer.colors = [UIColor.init(red: 103/255.0, green: 75/255.0, blue: 157/255.0, alpha: 1.0).cgColor, UIColor.init(red: 195/255.0, green: 74/255.0, blue: 130/255.0, alpha: 1.0).cgColor]
        self.topView.layer.addSublayer(gradientLayer)
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2.0
        profileImageView.layer.borderWidth = 5.0
        profileImageView.layer.borderColor = UIColor.white.cgColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }

    // MARK: - Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button Actions
    @IBAction func updateButtonTapped(_ sender: UIButton) {
        self.updateProfileApiCall(from: sender)
    }
    
    @IBAction func changeImageButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "Open Camera", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                    self.openCamera()
                } else if AVCaptureDevice.responds(to: #selector(AVCaptureDevice.requestAccess(for:completionHandler:))) {
                    AVCaptureDevice.requestAccess(for: .video, completionHandler: {(_ granted: Bool) -> Void in
                        if granted {
                            self.openCamera()
                        } else {
                            let settingsAlert = UIAlertController(title: "Camera permission is required", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                            settingsAlert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                                let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
                                UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
                            }))
                            settingsAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(settingsAlert, animated: true, completion: nil)
                        }
                    })
                }
            } else {
                Utility().showAlert(title: "Alert", message: "No camera available", controller: self)
            }
        }))
        alert.addAction(UIAlertAction(title: "Open Gallery", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            let controller = UIImagePickerController()
            controller.delegate = self
            controller.sourceType = .photoLibrary
            self.present(controller, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            print("cancel")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func doneWithNumberPad() {
        if let nextTextField = self.view.viewWithTag(activeTextField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - API Call
    func updateProfileApiCall(from sender: UIButton) {
        if Utility().reachable() {
            if activeTextField != nil {
                activeTextField.resignFirstResponder()
            }
            if isValid() {
                sender.isUserInteractionEnabled = false
                let indicator: UIActivityIndicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
                let halfButtonHeight: CGFloat = sender.bounds.size.height / 2
                let buttonWidth: CGFloat = sender.bounds.size.width
                indicator.center = CGPoint(x: buttonWidth/2, y: halfButtonHeight)
                indicator.translatesAutoresizingMaskIntoConstraints = true
                sender.setTitleColor(UIColor.clear, for: .normal)
                sender.addSubview(indicator)
                indicator.startAnimating()
                
                let jsonDict: NSMutableDictionary = NSMutableDictionary()
                
                jsonDict.setObject(nameTextField.text!, forKey: "name" as NSCopying)
                jsonDict.setObject(emailTextField.text!, forKey: "email" as NSCopying)
                jsonDict.setObject(phoneTextField.text!, forKey: "phone" as NSCopying)
                jsonDict.setObject(usernameTextField.text!, forKey: "username" as NSCopying)
                jsonDict.setObject(titleTextField.text!, forKey: "title" as NSCopying)
                jsonDict.setObject(locationTextField.text!, forKey: "location" as NSCopying)
                
                var img = ""
                if selectedImage != nil {
                    self.writeImage(inDocumentsDirectory: selectedImage)
                    img = "savedImage.png"
                }
                
                Utility().uploadImage(withFileName: img, withapi: "profile" as NSString, append: "", jsonDict: jsonDict as NSDictionary, forAction: "POST" as NSString, onController: self, completion: { response in
                    if response != nil && response.count > 1 {
                        DispatchQueue.main.async {
                            
                            if response.object(forKey: "success") as? Bool == true {
                                Utility().showAlert(title: "Success!", message: "Profile updated successfully", controller: self)
                            } else {
                                Utility().showAlert(title: "Alert!", message: response.object(forKey: "error_message") as! String, controller: self)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            Utility().showAlert(title: "Alert!", message: "No response from server", controller: self)
                        }
                    }
                })
                
                sender.isUserInteractionEnabled = true
                indicator.stopAnimating()
                indicator.removeFromSuperview()
                sender.setTitleColor(UIColor.white, for: .normal)
            }
        } else {
            Utility().showAlert(title: "Alert!", message: "No Internet Connection", controller: self)
        }
    }
    
    // MARK: - Methods
    func isValid() -> Bool {
        if self.nameTextField.text == nil || (self.nameTextField.text?.count)! == 0 {
            Utility().showAlert(title: "Alert!", message: "Please enter Name!", controller: self)
            return false
        }
        
        if self.emailTextField.text == nil || (self.emailTextField.text?.count)! == 0 {
            Utility().showAlert(title: "Alert!", message: "Please enter E-mail!", controller: self)
            return false
        }
        
        if !isValidEmail(testStr: self.emailTextField.text!) {
            Utility().showAlert(title: "Alert!", message: "Please enter a valid E-mail!", controller: self)
            return false
        }
        
        if self.phoneTextField.text == nil || (self.phoneTextField.text?.count)! == 0 {
            Utility().showAlert(title: "Alert!", message: "Please enter Phone!", controller: self)
            return false
        }
        
        if self.usernameTextField.text == nil || (self.usernameTextField.text?.count)! == 0 {
            Utility().showAlert(title: "Alert!", message: "Please enter Username!", controller: self)
            return false
        }
        
        if self.titleTextField.text == nil || (self.titleTextField.text?.count)! == 0 {
            Utility().showAlert(title: "Alert!", message: "Please enter Title!", controller: self)
            return false
        }
        
        return true
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func openCamera() {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = .camera
        self.present(controller, animated: true, completion: nil)
    }
    
    func writeImage(inDocumentsDirectory image: UIImage) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = paths[0]
        let savedImagePathStr: String = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("savedImage.png").absoluteString
        let imageData: Data? = UIImagePNGRepresentation(image)
        let savedImagePath: URL = URL(string: savedImagePathStr)!
        do {
            try imageData?.write(to: savedImagePath, options: .atomic)
        } catch {
            print(error)
        }
    }
    
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // MARK: - Keyboard Notification
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            var contentInset:UIEdgeInsets = mainScroll.contentInset
            contentInset.bottom = keyboardFrame.size.height
            DispatchQueue.main.async {
                self.mainScroll.contentInset = contentInset
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        mainScroll.contentInset = contentInset
    }
}

//MARK: - TextField Delegate

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 6 {
            textField.resignFirstResponder()
        } else {
            if let nextTextField = self.view.viewWithTag(textField.tag + 1) as? UITextField {
                nextTextField.becomeFirstResponder()
            }
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}

//MARK: - UIImagePickerController Delegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let imageData = UIImageJPEGRepresentation(image, 0.7)
            var newImage = UIImage.init(data: imageData!)!
            newImage = self.resizeImage(image: newImage, targetSize: CGSize(width: 115.0, height: 115.0))
            profileImageView.image = newImage
            selectedImage = newImage
        } else {
            print("Something went wrong")
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - View Extention

extension UIView {
    
    func addTopRoundedCornerToView(targetView: UIView?, desiredCurve: CGFloat?) {
        let offset:CGFloat =  targetView!.frame.width/desiredCurve!
        let bounds: CGRect = targetView!.bounds
        
        let rectBounds: CGRect = CGRect(x: bounds.origin.x, y: bounds.origin.y+bounds.size.height / 2, width: bounds.size.width, height: bounds.size.height / 2)
        
        let rectPath: UIBezierPath = UIBezierPath(rect: rectBounds)
        let ovalBounds: CGRect = CGRect(x: bounds.origin.x - offset / 2, y: bounds.origin.y, width: bounds.size.width + offset, height: bounds.size.height)
        let ovalPath: UIBezierPath = UIBezierPath.init(ovalIn: ovalBounds)
        rectPath.append(ovalPath)
        
        // Create the shape layer and set its path
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = rectPath.cgPath
        
        // Set the newly created shape layer as the mask for the view's layer
        targetView!.layer.mask = maskLayer
    }
}
