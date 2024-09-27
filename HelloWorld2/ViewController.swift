//
//  ViewController.swift
//  HelloWorld2
//
//  Created by Namer Mac on 9/25/24.
//

import UIKit
import AppsFlyerLib

class ViewController: UIViewController {

    @IBOutlet weak var helloWorldBtn: UIButton!
    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var executeCustomPurchaseBtn: UIButton!
    @IBOutlet weak var quantityField: UITextField!
    @IBOutlet weak var purchasePriceField: UITextField!
    @IBOutlet weak var purchaseItemField: UITextField!

    // List of currencies
    let currencies = ["USD", "CAD", "EUR", "GBP", "JPY", "AUD"]
    var selectedCurrency = "USD"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHelloBtn()
        setupCustomPurchaseBtn()
        setupCurrencyPicker()
        setupKeyboardObservers() // Add keyboard observer
        setupTapToDismissKeyboard()
    }
    
    // Setup tap gesture to dismiss keyboard
    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)  // This will dismiss the keyboard
    }
    
    deinit {
        removeKeyboardObservers() // Remove keyboard observer when deallocated
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardSize.cgRectValue.height
            self.view.frame.origin.y = -keyboardHeight / 1.25  // Move the view up by 3/4 the keyboard height
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0  // Reset the view position
    }
    
    private func setupCurrencyPicker() {
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        // Rotate the picker view 90 degrees
        currencyPicker.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    }
    
    private func setupHelloBtn() {
        helloWorldBtn.addTarget(self, action: #selector(triggerPurchaseEvent), for: .touchUpInside)
    }
    
    private func setupCustomPurchaseBtn() {
        executeCustomPurchaseBtn.addTarget(self, action: #selector(triggerCustomPurchaseEvent), for: .touchUpInside)
    }
    
    @objc private func triggerCustomPurchaseEvent(){
        guard quantityField.hasText && purchaseItemField.hasText && purchasePriceField.hasText else {
            let incompleteFieldsAlert = UIAlertController(title: "Incomplete Fields", message: "Need to fill out all fields before triggering purchase event. Try again.", preferredStyle: .alert)
            incompleteFieldsAlert.addAction(UIAlertAction(title: "Ok.", style: .cancel))
            present(incompleteFieldsAlert, animated: true)
            return
        }
        guard Int(quantityField.text!) != nil else {
            let quantityFieldAlert = UIAlertController(title: "Incorrect Entry", message: "Quantity field can only take 'Integer' values. Try again.", preferredStyle: .alert)
            quantityFieldAlert.addAction(UIAlertAction(title: "Ok.", style: .cancel))
            present(quantityFieldAlert, animated: true)
            return
        }
        guard Double(purchasePriceField.text!) != nil else {
            let priceFieldAlert = UIAlertController(title: "Incorrect Entry", message: "Price field can only take 'Double' values. Try again.", preferredStyle: .alert)
            priceFieldAlert.addAction(UIAlertAction(title: "Ok.", style: .cancel))
            present(priceFieldAlert, animated: true)
            return
        }
        let alert = setupTriggerCustomPurchaseAlert(item: purchaseItemField.text!, price: Double(purchasePriceField.text!)!, quantity: Int(quantityField.text!)!)
        self.present(alert, animated: true)
    }
    
    private func setupTriggerCustomPurchaseAlert(item: String, price: Double, quantity: Int) -> UIAlertController {
        let alert = UIAlertController(title: "Custom In-App Purchase Event", message: nil, preferredStyle: .alert)

        // Create a paragraph style to adjust alignment and spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left  // You can set it to .center if needed
        paragraphStyle.lineSpacing = 5  // Optional line spacing

        // Create an attributed string with alignment
        let messageText = """
        Simulating custom in-app purchase event ('af_purchase'):\n
        Item:           \(item)
        Price:          $\(price)
        Currency:       \(selectedCurrency)
        Quantity:       x\(quantity)
        Total Revenue:  $\(Double(quantity) * price)\n
        Do you want to continue?
        """
        
        let attributedMessage = NSAttributedString(string: messageText, attributes: [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14) // Adjust font size as needed
        ])
        
        // Use Key-Value Coding to set the attributed string
        alert.setValue(attributedMessage, forKey: "attributedMessage")

        // Add actions
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.appsFlyerCustomPurchaseEventAction()
        }))
        
        return alert
    }
    
    private func setupTriggerPurchaseAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Simulate In-App Event", message: "Clicking on 'Hello World' simulates an in-app purchase event ('af_purchase') with price ('af_price') and revenue ('af_revenue') of $29.99 in Australian currency ('af_currency'). Do you want to continue? ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.appsFlyerPurchaseEventAction()
        }))
        return alert
    }
    
    @objc private func triggerPurchaseEvent() {
        let alert = setupTriggerPurchaseAlert()
        self.present(alert, animated: true)
    }
    
    private func appsFlyerCustomPurchaseEventAction() {
        AppsFlyerLib.shared().logEvent(name: AFEventPurchase,
                                       values: [
                                        AFEventParamContent: purchaseItemField.text!,
                                        AFEventParamQuantity: quantityField.text!,
                                        AFEventParamPrice: Double(purchasePriceField.text!)!,
                                        AFEventParamRevenue: Double(quantityField.text!)!*Double(purchasePriceField.text!)!,
                                        AFEventParamCurrency: selectedCurrency
                                       ],
                                       completionHandler: { (response: [String: Any]?, error: Error?) in
            if let response = response {
                print("In-app event callback Success: ", response)
                let alert = UIAlertController(title: "In-App Event Success", message: "Great job! You have simulated a custom in-app purchase and received response: \(response)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            }
            if let error = error {
                print("In-app event callback ERROR: ", error.localizedDescription)
            }
        }
        )
    }
    
    private func appsFlyerPurchaseEventAction() {
        AppsFlyerLib.shared().logEvent(name: AFEventPurchase,
                                       values: [
                                        AFEventParamPrice: 29.99,
                                        AFEventParamRevenue: 29.99,
                                        AFEventParamCurrency: "AUD"
                                       ],
                                       completionHandler: { (response: [String: Any]?, error: Error?) in
            if let response = response {
                print("In-app event callback Success: ", response)
                let alert = UIAlertController(title: "In-App Event Success", message: "Great job! You have simulated an in-app event and received response: \(response)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            }
            if let error = error {
                print("In-app event callback ERROR: ", error.localizedDescription)
            }
        }
        )
    }
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCurrency = currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row]
    }
    
    // Customize picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        
        label.text = currencies[row]
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.backgroundColor = .clear
        label.transform = CGAffineTransform(rotationAngle: .pi / 2) // Rotate the picker text 90 degrees
        
        return label
    }
}
