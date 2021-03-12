//
//  ViewController.swift
//  StripeTutorialYouTube
//
//  Created by MD Tanvir Alam on 9/3/21.
//

import UIKit
import Stripe
import PassKit


class ViewController: UIViewController, STPPaymentContextDelegate,showSpinnerDelegate {

    var customerContext : STPCustomerContext?
    var paymentContext : STPPaymentContext?
    var isSetShipping = false
    var showspinner = true
    
    @IBOutlet weak var payNowButton: UIButton!
    lazy var cardTextField: STPPaymentCardTextField = {
            let cardTextField = STPPaymentCardTextField()
            return cardTextField
    }()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        activityIndicator.startAnimating()
        let config = STPPaymentConfiguration.shared
        //config.applePayEnabled = true
        config.shippingType = .shipping
        config.requiredShippingAddressFields = Set<STPContactField>(arrayLiteral: STPContactField.name,STPContactField.emailAddress,STPContactField.phoneNumber,STPContactField.postalAddress)
        config.companyName = "Testing XYZ"
        let myapiClient = MyAPIClient()
        myapiClient.delegate = self
        customerContext = STPCustomerContext(keyProvider: myapiClient)
        paymentContext =  STPPaymentContext(customerContext: customerContext!, configuration: config, theme: .defaultTheme)
        self.paymentContext?.delegate = self
        self.paymentContext?.hostViewController = self
        self.paymentContext?.paymentAmount = 5000
        payNowButton.isEnabled = paymentContext?.selectedPaymentOption != nil
    }
    
    func spinnerShouldStop() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    @IBAction func choosePaymentOptionsBtnTapped(_ sender: UIButton) {
        self.paymentContext?.presentPaymentOptionsViewController()
    }
    
    @IBAction func shippingButtonTapped(_ sender: UIButton) {
        self.paymentContext?.presentShippingViewController()
    }
    
    @IBAction func createCustomerPressed(_ sender: UIButton) {
        MyAPIClient.createCustomer()
    }
    
    @IBAction func payNow(_ sender: UIButton) {
        self.paymentContext?.requestPayment()
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    //DelegateFunctions
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        
        //self.activityIndicator.animating = paymentContext.loading
        self.payNowButton.isEnabled = paymentContext.selectedPaymentOption != nil
        
        
//        print("IN payment context did change result")
//        if paymentContext.selectedPaymentOption != nil && !isSetShipping{
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                paymentContext.presentShippingViewController()
//            }
//        }
//
//        if paymentContext.selectedShippingMethod != nil && isSetShipping {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//
//                print("This is the ultimate FINAL")
//                self.paymentContext?.requestPayment()
//            }
//        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
        
        isSetShipping = true
        
        let upsGround = PKShippingMethod()
        upsGround.amount = 0
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        
        let fedEx = PKShippingMethod()
        fedEx.amount = 5.99
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"
        print("IN didupdate shipping address result")
        if address.country == "US" {
            completion(.valid, nil, [upsGround, fedEx], upsGround)
        }
        else {
            completion(.invalid, nil, nil, nil)
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        
        print("IN Didpayment result")
        
        MyAPIClient.createPaymentIntent(amount: (Double(paymentContext.paymentAmount+Int(truncating: (paymentContext.selectedShippingMethod?.amount)!))), currency: "usd",customerId: "cus_J571UGs6nwtzwC") { (response) in
            switch response {
            case .success(let clientSecret):
                // Assemble the PaymentIntent parameters
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentResult.paymentMethod?.stripeId
                paymentIntentParams.paymentMethodParams = paymentResult.paymentMethodParams
                
                STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: paymentContext) { status, paymentIntent, error in
                    switch status {
                    case .succeeded:
                        // Your backend asynchronously fulfills the customer's order, e.g. via webhook
                        completion(.success, nil)
                    case .failed:
                        completion(.error, error) // Report error
                    case .canceled:
                        completion(.userCancellation, nil) // Customer cancelled
                    @unknown default:
                        completion(.error, nil)
                    }
                }
            case .failure(let error):
                completion(.error, error) // Report error from your API
                break
            }
        }
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        switch status {
            case .error:
                showAlert(title: "Hello", messsage: "Payment was NOT successful")
            case .success:
                showAlert(title: "Hello", messsage: "Payment was Successful")
            case .userCancellation:
                print("User Cancelled")
                return // Do nothing
        }
    }
    
    func showAlert(title:String,messsage:String){
        let alert = UIAlertController(title: title, message: messsage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

