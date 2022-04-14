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
        
        //test
        let httpRequest = HTTPRequest() //self-made class,wrap up the native swift network method
//        httpRequest.authLogin(url: Hi5API.loginURL, data: "test")
        httpRequest.verifyLogin(url: Hi5API.loginURL, uploadData: nil)
    }

    @IBAction func LoginButtonTapped(_ sender: Any) {
        // check inputs
        
        // send HTTP request
        // create json
        let loginUser = loginUser(name: emailTextField.text!, passwd: passwordTextField.text!) //after check inputs, so force unwarp
        let jsonString = Hi5API.generateLoginJSON(loginUser: loginUser)
        guard jsonString != nil else {return}
        print(jsonString ?? "no json")
        let httpRequest = HTTPRequest() //self-made class,wrap up the native swift network method
        httpRequest.authLogin(url: Hi5API.loginURL, data: jsonString!)
        
        // check auth results
    }
}
