//
//  Local Authentication.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 24/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import LocalAuthentication

class LocalAuthentication {
    
    public static func authenticate(reason: String, completion: @escaping ()->(), failure: @escaping ()->()) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                (success, authenticationError) in
                
                DispatchQueue.main.async {
                    if success {
                        completion()
                    } else {
                        failure()
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                (success, authenticationError) in
                
                DispatchQueue.main.async {
                    if success {
                        completion()
                    } else {
                        failure()
                    }
                }
            }
        }
    }
}
