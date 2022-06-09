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
    var UserPref:UserPreferences!
    
    override func viewWillAppear(_ animated: Bool) {
        // for read user pref
        if loadUserPref() {
            emailTextField.text = UserPref.username
            passwordTextField.text = UserPref.password
            if UserPref.autoLogin && emailTextField.text != "" && passwordTextField.text != "" {
                LoginButtonTapped(self)
            }
        }
    }
    
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
        HTTPRequest.UserPart.login(name: emailTextField.text!, passwd: passwordTextField.text!) { [self]
                loginFeedBack in
                if let loginResult = loginFeedBack {
                    print("user \(loginResult.name) login successfully")
                    self.loginNewUser = User(userName: loginResult.name, nickName: loginResult.nickname, email: loginResult.email, password: self.passwordTextField.text!, inviterCode: loginResult.appkey, score: loginResult.score)
                    // jump to home screen
                    let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "homeVC") as! HomeViewController
                    nextViewController.loginUser = self.loginNewUser // pass user info to home screen
                    if var userPref = self.UserPref{
                        userPref.username = emailTextField.text!
                        userPref.password = passwordTextField.text!
                        nextViewController.userPref = userPref // pass user pref
                    }
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
    
    func saveUserPref(){
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("userPref.plist"){
            do{
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(UserPref)
                try data.write(to: documentURL,options: .atomic)
                print("user pref saved")
            }catch{
                print("user pref save failed")
            }
        }
    }
    
    func loadUserPref()->Bool{
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("userPref.plist"){
            do{
                let data = try Data(contentsOf: documentURL)
                let unarchiver = PropertyListDecoder()
                UserPref = try unarchiver.decode(UserPreferences.self, from: data)
                print("user pref loaded in login screen")
                return true
            }catch{
                print("user pref load in login screen failed")
                return false
            }
        }
        return false
    }
}
