//
//  Postnummer.swift
//  PerData
//
//  Created by Jan Hovland on 25/11/2026.
//

import Foundation

struct Postnummer: Identifiable  {
    let postnummer: String
    let poststed: String
    let kommunenummer: String
    let kommune: String
    let posttype: String

    var id: String {
        postnummer + posttype
    }
}
