//
//  PasswordViewController.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 3/8/17.
//  Copyright © 2017 Jarco Katsalay. All rights reserved.
//

import UIKit
import LocalAuthentication

class PasswordViewController: UIViewController, UITextFieldDelegate {
    
    var staticPassword: String?
    let authentication = Authentication()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        staticPassword = try? authentication.passwordItem.readPassword()

        authenticateUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var passwordTextView: UITextField! {
        didSet {
            let fingerprintButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            if let image = UIImage(named: "Fingerprint.png") {
                fingerprintButton.setImage(image, for: .normal)
            }
            fingerprintButton.addTarget(self, action: #selector(fingerprintButtonTapped), for: .touchUpInside)
            
            passwordTextView.rightViewMode = UITextFieldViewMode.always
            passwordTextView.rightView = fingerprintButton
            
            passwordTextView.keyboardType = .numberPad
            
            passwordTextView.delegate = self
        }
    }
    
    @IBAction func passwordEditing(_ sender: UITextField) {
        if staticPassword ?? "" == sender.text ?? "" {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func fingerprintButtonTapped() {
        authenticateUser()
        passwordTextView.resignFirstResponder()
    }
    
    func authenticateUser() {
        let myContext = LAContext()
        let myLocalizedReasonString = "Authentication needed"
        
        var authError: NSError? = nil
        if #available(iOS 8.0, OSX 10.12, *) {
            if myContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                myContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: myLocalizedReasonString) { [ unowned self] (success, evaluateError) in
                    if (success) {
                        self.dismiss(animated: false, completion: nil)
                    } else {
                        let when = DispatchTime.now() + 0.25
                        DispatchQueue.main.asyncAfter(deadline: when) {
                            self.passwordTextView.becomeFirstResponder()
                        }
                    }
                }
            } else {
                passwordTextView.becomeFirstResponder()
            }
        } else {
            passwordTextView.becomeFirstResponder()
        }
    }
    
    
    @IBOutlet weak var imageContainer: UIView!
    
    @IBOutlet weak var mainImage: UIImageView! {
        didSet {
            mainImage.layer.cornerRadius = mainImage.frame.size.height/4
            mainImage.clipsToBounds = true
            
            imageContainer.backgroundColor = UIColor.clear
            imageContainer.layer.shadowColor = UIColor.black.cgColor
            imageContainer.layer.shadowOffset = CGSize(width: 2, height: 2)
            imageContainer.layer.shadowOpacity = 0.5
            imageContainer.layer.shadowRadius = 3
            
            imageContainer.layer.shadowPath = UIBezierPath(roundedRect: imageContainer.bounds, cornerRadius: imageContainer.frame.size.height/4).cgPath
        }
    }

    // MARK: - UITFDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string) as NSString
        return newString.length <= 4
    }

}
