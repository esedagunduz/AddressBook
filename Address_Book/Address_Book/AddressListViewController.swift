//
//  AddressListViewController.swift
//  Address_Book
//
//  Created by ebrar seda gündüz on 11.04.2025.
//

// AddressListViewController.swift

import UIKit
import RealmSwift

class AddressListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    let realm = try! Realm()
    var addresses: Results<Address>!
    var filteredAddresses: Results<Address>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        addresses = realm.objects(Address.self)
        filteredAddresses = addresses

        navigationItem.title = "Adresler"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addButtonTapped))
        navigationController?.navigationBar.tintColor = UIColor(red: 109/255, green: 132/255, blue: 46/255, alpha: 1)
    }

    @objc func addButtonTapped() {
        performSegue(withIdentifier: "toAddAddress", sender: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAddresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        let address = filteredAddresses[indexPath.row]
        cell.textLabel?.text = "\(address.name) - \(address.phone) - \(address.address)"
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { (_, _, completionHandler) in
            let addressToDelete = self.filteredAddresses[indexPath.row]
            try! self.realm.write {
                self.realm.delete(addressToDelete)
            }
            self.refreshAddresses()  // Adresler yenilendikten sonra tabloyu güncelle
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }

    // Search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredAddresses = addresses
        } else {
            filteredAddresses = addresses.filter("name CONTAINS[c] %@", searchText)
        }
        tableView.reloadData()  // Arama sırasında tabloyu güncelle
    }

    // Veritabanını ve tablodaki verileri yenileme
    func refreshAddresses() {
        addresses = realm.objects(Address.self)
        filteredAddresses = searchBar.text?.isEmpty == false
            ? addresses.filter("name CONTAINS[c] %@", searchBar.text!)
            : addresses
        tableView.reloadData()  // Tabloyu güncelle
    }

  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Adresler yenilendiğinde tekrar yükle
        refreshAddresses()  // viewWillAppear'da adresleri yenile
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQRCode",
           let destinationVC = segue.destination as? QRCodeViewController,
           let address = sender as? Address {
            destinationVC.address = address
        }
    }

}

extension AddressListViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAddress = filteredAddresses[indexPath.row]
        // QR kodu sayfasına yönlendirme
        showQRCode(for: selectedAddress)
    }

    func showQRCode(for address: Address) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let qrVC = storyboard.instantiateViewController(withIdentifier: "QRCodeViewController") as? QRCodeViewController {
            qrVC.address = address
            navigationController?.pushViewController(qrVC, animated: true)
        }
    }
}
