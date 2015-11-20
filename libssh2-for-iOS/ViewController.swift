//
//  ViewController.swift
//  libssh2-for-iOS
//
//  Created by Felix Schulze on 01.02.11.
//  Copyright 2010-2015 Felix Schulze. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var ipField: UITextField!
    @IBOutlet var userField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var textView: UITextView!

    
    @IBAction
    func showInfo() {
        let message = "libssh2-Version: \(LIBSSH2_VERSION)\nlibgcrypt-Version: \(GCRYPT_VERSION)\nlibgpg-error-Version: 1.12\nopenssl-Version:\(OPENSSL_VERSION_TEXT)\nLicense: See include/LICENSE\n\nCopyright 2010-2015 by Felix Schulze\n http://www.felixschulze.de"
        let alertController = UIAlertController(title: "libssh2-for-iOS", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction
    func executeCommaned() {
        
        let sshWrapper = SSHWrapper()
        var error: NSError?

        sshWrapper.connectToHost(ipField.text, port: 22, user: userField.text, password: passwordField.text, error: &error)
        
        if error != nil {
            let alertController = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            var result: String?

            do {
                result = try sshWrapper.executeCommand(textField.text)
            }
            catch {
                result = "Error"
            }
            textField.text = result
        }
        textField.resignFirstResponder()
        ipField.resignFirstResponder()
        userField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "libssh2-for-iOS"
        let infoButton = UIButton(type: .InfoLight)
        infoButton.addTarget(self, action: "showInfo", forControlEvents: .TouchDown)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }
}
