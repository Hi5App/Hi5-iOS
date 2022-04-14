//
//  LoginViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/12.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var stackView: UIStackView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var errorTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorTextField.alpha = 0
        stackView.setCustomSpacing(0, after: passwordTextField)
        stackView.setCustomSpacing(0, after: errorTextField)
        
    }

    @IBAction func LoginButtonTapped(_ sender: Any) {
        // check inputs
        
        // send HTTP request
        let loginUser = loginUser(user:user(name: emailTextField.text!, passwd: passwordTextField.text!))
        let jsonData = Hi5API.generateLoginJSON(loginUser: loginUser)
        guard jsonData != nil else {return}
        print("json data is:\n" + String(data: jsonData!, encoding: .utf8)!)
        let httpRequest = HTTPRequest() //self-made class,wrap up the native swift network method
        httpRequest.verifyLogin(url: Hi5API.loginURL, uploadData: jsonData!)
        
        // handle results
        
    }
}
