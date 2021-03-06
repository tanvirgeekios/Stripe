//
//  MyAPIClient.swift
//  StripeTutorialYouTube
//
//  Created by MD Tanvir Alam on 9/3/21.
//

import Foundation
import Alamofire
import Stripe

struct K {
    static let baseUrl:String = "http://192.168.0.102:8888/StripeBackend/"
    static let createCustomer:String = "createcustomer.php"
    static let ephemeralKey:String = "empheralkey.php"
    static let createPaymentIntent = "createpaymentintent.php"
}
protocol showSpinnerDelegate {
    func spinnerShouldStop()
}
class MyAPIClient:NSObject,STPCustomerEphemeralKeyProvider {
    
    var delegate:showSpinnerDelegate?
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let parameters = ["api_version":apiVersion]
        
        AF.request(URL(string: K.baseUrl+K.ephemeralKey)!, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: [:]).responseJSON { (apiResponse) in
            if let data = apiResponse.data{
                guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) as [String : Any]??) else {
                    print("Error: \(apiResponse.error)")
                    completion(nil, apiResponse.error)
                    return
                }
                print("Json:\(json)")
                completion(json, nil)
                self.delegate?.spinnerShouldStop()
            }
            
            
        }
    }
    
    
    //Create Customer and get Customer ID
    class func createCustomer(){
        
        var customerDetailParams = [String:String]()
        customerDetailParams["email"] = "tes675t@gmail.com"
        customerDetailParams["phone"] = "8888888888"
        customerDetailParams["name"] = "test"
        
        AF.request(URL(string:K.baseUrl+K.createCustomer)!, method: .post, parameters: customerDetailParams, encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            
            switch response.result {
            
            case .success(let value):
                print("Alamo value: \(value)")
                break
            case .failure(let error):
                print("Alamo error: \(error)")
                break
            }
        }
    }
    
    class func createPaymentIntent(amount:Double,currency:String,customerId:String,completion:@escaping (AFResult<String>)->Void){
        //        createpaymentintent.php
        
        print("NOTICE createPaymentIntent")
        AF.request(URL(string: K.baseUrl+K.createPaymentIntent)!, method: .post, parameters: ["amount":amount,"currency":currency,"customerId":customerId], encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            
            switch response.result {
            case .success(let value):
                let data = response.data
                guard let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : String]) as [String : String]??) else {
                    print("ResponseCreatepaymentIntent failure:\(response.error!)")
                    completion(.failure(response.error!))
                    return
                }
                print("ResponseCreatepaymentIntent: \(json!["clientSecret"]!)")
                completion(.success(json!["clientSecret"]!))
                break
            case .failure(let error):
                print("ResponseCreatepaymentIntent Failure: \(error)")
                completion(.failure(error))
                break
            }
            
            
        }
    }
}
