//
//  HomeController.swift
//  Example iOS
//
//  Created by Yeh MinHsuan on 2019/12/8.
//  Copyright © 2019 Shogo Endo. All rights reserved.
//

import AVFoundation
import HaishinKit
import Photos
import UIKit

final class HomeController: UIViewController {
    @IBOutlet private weak var projectNameField: UITextField?
    @IBOutlet private weak var submitButton: UIButton?
    
    private var flag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        projectNameField?.layer.borderWidth = 1
        projectNameField?.layer.borderColor = UIColor.black.cgColor
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func on(submit: UIButton) {
        let url = URL(string: "http://140.118.127.145:3000")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary+\(arc4random())\(arc4random())"
        var body = Data()
        var file: String
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent("camera_parameter.yml")
            do {
                file = try String(contentsOf: filePath, encoding: .utf8)
            } catch {
                self.view.showToast(text: "camera_parameter.yml not found!\nPlease Set Calibration!")
                return
            }
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"name\"\r\n\r\n".utf8))
            body.append(Data("\(projectNameField?.text)\r\n".utf8))

            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"calibration\"; filename=\"\(arc4random())\"\r\n".utf8))
            body.append(Data("Content-Type: text/yaml\r\n\r\n".utf8))
            body.append(Data(file.utf8))
            body.append(Data("\r\n".utf8))
            body.append(Data("--\(boundary)--\r\n".utf8))
            
            request.httpBody = body
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            self.flag = false
            guard error == nil else {
                return
            }
            DispatchQueue.main.async {
                let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "PopUpLive")
                self.present(secondViewController!, animated: true, completion: nil)
            }
        })
        if (flag == false) {
            task.resume()
        }
        flag = true
    }
}

extension UIView{

    func showToast(text: String){
        
        let toastLb = UILabel()
        toastLb.numberOfLines = 0
        toastLb.lineBreakMode = .byWordWrapping
        toastLb.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLb.textColor = UIColor.white
        toastLb.layer.cornerRadius = 10.0
        toastLb.textAlignment = .center
        toastLb.font = UIFont.systemFont(ofSize: 15.0)
        toastLb.text = text
        toastLb.layer.masksToBounds = true
        toastLb.tag = 9999
        
        let maxSize = CGSize(width: self.bounds.width - 40, height: self.bounds.height)
        var expectedSize = toastLb.sizeThatFits(maxSize)
        var lbWidth = maxSize.width
        var lbHeight = maxSize.height
        if maxSize.width >= expectedSize.width{
            lbWidth = expectedSize.width
        }
        if maxSize.height >= expectedSize.height{
            lbHeight = expectedSize.height
        }
        expectedSize = CGSize(width: lbWidth, height: lbHeight)
        toastLb.frame = CGRect(x: ((self.bounds.size.width)/2) - ((expectedSize.width + 20)/2), y: self.bounds.height - expectedSize.height - 40 - 20, width: expectedSize.width + 20, height: expectedSize.height + 20)
        self.addSubview(toastLb)
        
        UIView.animate(withDuration: 1.5, delay: 1.5, animations: {
            toastLb.alpha = 0.0
        }) { (complete) in
            toastLb.removeFromSuperview()
        }
        
    }
    
    func hideToast(){
        for view in self.subviews{
            if view is UILabel , view.tag == 9999{
                view.removeFromSuperview()
            }
        }
    }
}
