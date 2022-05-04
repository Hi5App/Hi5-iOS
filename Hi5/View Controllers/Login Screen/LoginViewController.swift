//
//  LoginViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/12.
//

import UIKit

extension UITextField{
    func checkForEmpty()->Bool{
        if let text = self.text,!text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty{
            return true // true when it's not empty
        }else{
            return false
        }
    }
}

class LoginViewController: UIViewController {

    @IBOutlet var stackView: UIStackView!
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var errorTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var guestModeLabel: UILabel!
    @IBOutlet var forgetPasswordLabel: UILabel!
    var loginNewUser:User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor.systemOrange
        // set background image
        let backgroundImage = UIImage(named: "bg_login_1")
        let backgroundImageView = UIImageView.init(frame: self.view.frame)
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.alpha = 0.9
        self.view.insertSubview(backgroundImageView, at: 0)
        // set logo image
        logoImageView.image = UIImage(named: "logo")
        
        errorTextField.alpha = 0
        // for debug
        emailTextField.text = "kx1126"
        passwordTextField.text = "123456"
//        LoginButtonTapped(signInButton!)
        
        stackView.setCustomSpacing(0, after: passwordTextField)
        stackView.setCustomSpacing(0, after: errorTextField)
        setupGestures()
    }

    @IBAction func LoginButtonTapped(_ sender: Any) {
            // check inputs
        guard emailTextField.checkForEmpty() && passwordTextField.checkForEmpty() else{
            let alert = UIAlertController(title: "Attention", message: "Username and Password can not be empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            return
        }
            // send HTTP request
            HTTPRequest.UserPart.login(name: emailTextField.text!, passwd: passwordTextField.text!) {
                loginFeedBack in
                if let loginResult = loginFeedBack {
                    print("user \(loginResult.name) login successfully")
                    self.loginNewUser = User(userName: loginResult.name, nickName: loginResult.nickname, email: loginResult.email, password: self.passwordTextField.text!, inviterCode: loginResult.appkey, score: loginResult.score)
                    // jump to home screen
                    let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "homeVC") as! HomeViewController
                    nextViewController.loginUser = self.loginNewUser // pass user info to home screen
                    self.navigationController?.pushViewController(nextViewController, animated: true)
                }
            } errorHandler: {
                error in
                let alert = UIAlertController(title: "Login Failed", message: "Please check your username or password and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel,handler: { (action) in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true)
                print(error)
            }
        
        }
    
    func showErrorMessage(message:String){
        errorTextField.alpha = 1
        errorTextField.textColor = UIColor.systemRed
        errorTextField.text = message
    }
    // MARK: - set up gesture recognizer
    func setupGestures(){
        let tapOnBackground = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        let tapOnGuestLabel = UITapGestureRecognizer(target: self, action: #selector(goHomeAsGuest))
        self.view.addGestureRecognizer(tapOnBackground)
        self.guestModeLabel.isUserInteractionEnabled = true
        self.guestModeLabel.addGestureRecognizer(tapOnGuestLabel)
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    @objc func goHomeAsGuest(){
        let guestUser = User.guestUser()
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "homeVC") as! HomeViewController
        nextViewController.loginUser = guestUser // pass user info to home screen
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}
