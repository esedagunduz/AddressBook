//
//  AddAddressViewController.swift
//  Address_Book
//
//  Created by ebrar seda gündüz on 11.04.2025.
//

// AddAddressViewController.swift

import UIKit
import RealmSwift
import AVFoundation

class AddAddressViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!

    let realm = try! Realm()
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneTextField.delegate = self  // Delegateyi burada ayarlıyoruz
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let newAddress = Address()
        newAddress.name = nameTextField.text ?? ""
        newAddress.phone = phoneTextField.text ?? ""
        newAddress.address = addressTextField.text ?? "" // Adres burada kaydediliyor

        if newAddress.address.isEmpty {
            // Adres alanı boşsa uyarı göster
            let alert = UIAlertController(title: "Hata", message: "Adres alanı boş olamaz.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }

        try! realm.write {
            realm.add(newAddress)
        }

        navigationController?.popViewController(animated: true)
    }

    
    @IBAction func scanQRCodeButtonTapped(_ sender: UIButton) {
        // QR kodu okutmaya başla
        startScanning()
    }

    func startScanning() {
        captureSession = AVCaptureSession()

        // Kameraya erişim sağla
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoDeviceInput: AVCaptureDeviceInput

        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        // Capture session'a input ekle
        if (captureSession.canAddInput(videoDeviceInput)) {
            captureSession.addInput(videoDeviceInput)
        } else {
            return
        }

        // QR kod çıktısını ayarla
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            // QR kodunu okuma işlemi için delegate ayarla
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]  // QR kodlarını okumak
        } else {
            return
        }

        // Video preview layer'ı oluştur
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.layer.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)

        captureSession.startRunning()
    }

    // QR kodu okunduğunda bu metod çalışacak
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            foundQRCode(stringValue)
        }
    }

    func foundQRCode(_ string: String) {
        // QR kodu verisini ayır
        let addressComponents = string.split(separator: ",")
        
        // 3 parametre bekliyoruz: ad, telefon, adres
        if addressComponents.count == 3 {
            let name = String(addressComponents[0])
            let phone = String(addressComponents[1])
            let addressText = String(addressComponents[2])

            nameTextField.text = name
            phoneTextField.text = phone
            addressTextField.text = addressText

            // Adresi Realm'e kaydet
            let newAddress = Address()
            newAddress.name = name
            newAddress.phone = phone
            newAddress.address = addressText

            try! realm.write {
                realm.add(newAddress)
            }

            // Geriye dön veya kullanıcıya bilgi gösterilebilir
            let alert = UIAlertController(title: "Başarılı", message: "Adres başarıyla eklendi.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true, completion: nil)
        } else {
            // QR formatı hatalıysa
            let alert = UIAlertController(title: "Hata", message: "QR kod formatı geçersiz. Beklenen format: 'Ad, Telefon, Adres'.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }

        captureSession.stopRunning()
        videoPreviewLayer.removeFromSuperlayer()
    }

    // Telefon numarası formatını kontrol et
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Yalnızca sayılar ve geri silme (backspace) izin verilsin
        let allowedCharacters = CharacterSet.decimalDigits
        
        // Geri silme (backspace) işlemi kontrolü
        if string == "" {
            return true
        }
        
        // Yeni karakterin sayısal olup olmadığını kontrol et
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false  // Eğer sayı değilse girilmesine izin verilmeyecek
        }
        
        // Telefon numarasına sadece 10 haneli (5xx)-xxxxxxx formatına uyan değerler ekle
        let currentText = (textField.text ?? "") + string
        let digitsOnly = currentText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.count > 10 {
            return false  // 10 haneli olmamalı
        }
        
        // Formatı (5XX)-XXXXXXX olarak değiştir
        if digitsOnly.count >= 1 {
            var formattedNumber = ""
            
            // İlk 3 rakam için parantez içinde format
            if digitsOnly.count <= 3 {
                formattedNumber = "(" + digitsOnly + ")"
            } else {
                // 3 rakamdan sonra parantez ve tire ekle
                let firstPart = digitsOnly.prefix(3)
                let secondPart = digitsOnly.suffix(from: digitsOnly.index(digitsOnly.startIndex, offsetBy: 3))
                formattedNumber = "(\(firstPart))-\(secondPart)"
            }
            
            textField.text = formattedNumber
            return false
        }
        
        return true
    }
}
