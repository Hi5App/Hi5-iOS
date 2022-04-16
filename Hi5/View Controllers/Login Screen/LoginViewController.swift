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
    var loginNewUser:User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorTextField.alpha = 0
        stackView.setCustomSpacing(0, after: passwordTextField)
        stackView.setCustomSpacing(0, after: errorTextField)
        
    }

    @IBAction func LoginButtonTapped(_ sender: Any) {
        // check inputs
        
        // send HTTP request
        HTTPRequest.UserPart.login(name: emailTextField.text!, passwd: passwordTextField.text!) {
            loginFeedBack in
            if let loginResult = loginFeedBack {
                print("user \(loginResult.id) login successfully")
                self.loginNewUser = User(userName: loginResult.name, nickName: loginResult.nickname, email: loginResult.email, password: self.passwordTextField.text!, inviterCode: loginResult.appkey, score: loginResult.score)
                // jump to home screen
                let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "homeVC") as! HomeViewController
                nextViewController.loginUser = self.loginNewUser // pass user info to home screen
                self.navigationController?.pushViewController(nextViewController, animated: true)
            }
        }
    }
}
