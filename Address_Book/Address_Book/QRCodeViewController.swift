//
//  QRCodeViewController.swift
//  Address_Book
//
//  Created by ebrar seda gündüz on 12.04.2025.
//


import UIKit
import CoreImage

class QRCodeViewController: UIViewController {
    
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var qrInfoLabel: UILabel!
    
    var address: Address?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        navigationItem.title = "QR Kod"
        
        // Debug printing
        print("Address object: \(String(describing: address))")
        print("Address value: \(address?.address ?? "nil")")
        
        if let address = address {
            let infoText = """
            İsim: \(address.name)
            Telefon: \(address.phone)
            Adres: \(address.address)
            """
            print("Info text being set: \(infoText)")
            qrInfoLabel.text = infoText
            let qrString = "\(address.name),\(address.phone),\(address.address)"
            qrImageView.image = generateQRCode(from: qrString)
        }
    }


    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")

            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                return UIImage(ciImage: scaledImage)
            }
        }

        return nil
    }
}

