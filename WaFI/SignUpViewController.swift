//
//  SignUpViewController.swift
//  WaFI
//
//  Created by Paul Sumido on 2018-06-07.
//  Copyright © 2018 Paul Sumido. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController {

    //MARK:Properties
    @IBOutlet weak var emailEditText: UITextField!
    @IBOutlet weak var passwordEditText: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func createAccount(_ sender: UIButton) {
        if emailEditText.text == "" { //check if user filled in email text field
            //if did not fill email, present alert
            let alertController = UIAlertController(title: "Error", message: "Please enter your email and password", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
        } else { //if filled in email
            //check if email and password are set
            Auth.auth().createUser(withEmail: emailEditText.text!, password: passwordEditText.text!) { (user, error) in
                //if both set, create account
                if error == nil {
                    print("You have successfully signed up")
                    
                    //goes to home once complete
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "startingNavigation")
                    self.present(vc!, animated: true, completion: nil)
                //if not both set, alert user
                } else {
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
