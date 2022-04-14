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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
