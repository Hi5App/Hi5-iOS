//
//  RegisterViewController.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/4/12.
//

import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var nicknameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var passwordCheckTextField: UITextField!
    @IBOutlet var inviterCodeTextField: UITextField!
    @IBOutlet var errorTextField: UITextField!
    @IBOutlet var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorTextField.alpha = 0
        stackView.setCustomSpacing(0, after: inviterCodeTextField)
        stackView.setCustomSpacing(0, after: errorTextField)

        // Do any additional setup after loading the view.
    }
   
    @IBAction func RegisterButtonTapped(_ sender: Any) {
        // check for fields
        guard usernameTextField.checkForEmpty() && emailTextField.checkForEmpty() && nicknameTextField.checkForEmpty()
                && passwordTextField.checkForEmpty() && passwordCheckTextField.checkForEmpty() else {
            let alert = UIAlertController(title: "Attention", message: "Please fill in all the field except Inviter Code", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            return
        }
        
        HTTPRequest.UserPart.register(email: emailTextField.text!, name: usernameTextField.text!, passwd: passwordTextField.text!, nickname: nicknameTextField.text!) { [self] in
            print("user:\(usernameTextField.text!) with nickname:\(nicknameTextField.text!) with email:\(emailTextField.text!) registered successfully")
        } errorHandler: { error in
            print(error)
        }

    }
    

}
