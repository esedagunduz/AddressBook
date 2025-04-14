//
//  Address.swift
//  Address_Book
//
//  Created by ebrar seda gündüz on 11.04.2025.
//

import Foundation
import RealmSwift

class Address: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var phone: String = ""
    @objc dynamic var address: String = ""
}
