//
//  ZipCodeZoom.swift
//  PerData
//
//  Created by Jan Hovland on 24/11/2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// Finne det rette formatet på Postnummerregister-ansi.txt filen:
/// Gå til https://www.bring.no/tjenester/adressetjenester/postnummer
///
/// Hent: Tab-separerte felter (ANSI)
/// Kopier direkte fra det som vises på skjermen
/// Erstatt disse tegnene med:
///  ∆ mrd  Æ
///  ÿ med  Ø
///  ≈ med  Å
///  ¡ med   O    9716    BÿRSELV    5436    PORSANGER PORS¡NGU PORSANKI    G
///  Ferdig!

import SwiftUI

struct ZipCodeZoom: View {

    @State private var searchText = ""
    @State private var results: [Postnummer] = []
    @State private var errorMessage = ""
    
    @Binding var person: Person
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                ScrollView(showsIndicators: false) {
                    // Antall treff
                    HStack {
                        Text("\(results.count) \(String(localized: "treff"))")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    // Resultater
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(results) { (item: Postnummer) in
                            ///
                            /// posttype == G   Gateadresser (og stedsadresser), dvs. “grønne postkasser”
                            /// posttype == P   Postbokser
                            /// posttype == B   Både gateadresser og postbokser
                            /// posttype == S   Servicepostnummer (disse postnumrene er ikke i bruk til postadresser)
                            ///
                            if item.posttype != "S" {
                                HStack {
                                    Spacer()
                                    Text(item.postnummer)
                                        .frame(width: 55, alignment: .leading)
                                    
                                    let poststed = item.poststed
                                    let newPoststed = replaceStringCharacters(in: poststed, option: .forward)
                                    Text(newPoststed)
                                    
                                    Text(item.kommunenummer)
                                    
                                    let kommune = item.kommune
                                    let newkommune = replaceStringCharacters(in: kommune, option: .forward)
                                    Text(newkommune)
                                    
                                    Text(item.posttype)
                                    Spacer()
                                }
                                .font(.system(.body, design: .monospaced))
                                .gradientGlass()
                                .onTapGesture {
                                    $person.wrappedValue.cityNumber = item.postnummer
                                    $person.wrappedValue.city = replaceStringCharacters(in: item.poststed, option: .forward)
                                    $person.wrappedValue.municipalityNumber = item.kommunenummer
                                    $person.wrappedValue.municipality = replaceStringCharacters(in: item.kommune, option: .forward)
                                    ///
                                    /// Return til "Oppdater person"
                                    ///
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationBarTitle("ZipCode", displayMode: .inline)
            .task {
                search()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search ZipCode...")
            .onChange(of: searchText) { _, _ in
                searchText = searchText.uppercased()
                Task {
                    search()
                }
              }
            .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Søk
    private func search() {
        results = []
        errorMessage = ""
        
        let search = searchText.uppercased()
        let newSearchText = replaceStringCharacters(in: search, option: .backward)

        let searchValue = newSearchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchValue.isEmpty else {
            return
        }
        guard let fileURL = Bundle.main.url(
            forResource: "Post",
            withExtension: "txt"
        ) else {
            errorMessage = "No Post.txt"
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let content = String(
                decoding: data,
                as: UTF8.self
            )
            let lines = content.components(separatedBy: "\r\n") //.newlines)
            results = lines.compactMap { line in
                parseLine(line)
            }
            .filter { item in
                item.poststed.folding(
                    options: [.caseInsensitive, .diacriticInsensitive],
                    locale: Locale(identifier: "nb_NO")
                )
                .contains(
                    searchValue.folding(
                        options: [.caseInsensitive, .diacriticInsensitive],
                        locale: Locale(identifier: "nb_NO")
                    )
                )
            }
            if results.isEmpty {
                errorMessage = "No hits"
            }
        } catch {
            errorMessage = "Reading error of the file"
            print("Lesefeil:", error.localizedDescription)
        }
    }

    // MARK: - Les én linje
    private func parseLine(_ line: String) -> Postnummer? {
        let trimmedLine = line.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedLine.isEmpty else {
            return nil
        }
        // Støtter tabulatorer eller minst to mellomrom.
        let columns = trimmedLine
            .replacingOccurrences(
                of: #"\t+| {2,}"#,
                with: "|",
                options: .regularExpression
            )
            .components(separatedBy: "|")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        guard columns.count == 5 else {
            return nil
        }
        return Postnummer(
            postnummer: columns[0],
            poststed: columns[1],
            kommunenummer: columns[2],
            kommune: columns[3],
            posttype: columns[4]
        )
    }
}

func replaceStringCharacters(in string: String, option: EnumType) -> String {
    
    var result = string
    
    if option == .forward {
        let replacements: [(old: String, new: String)] = [
            ("[", "Æ"),
            ("]", "Ø"),
            ("}", "Å")
        ]
        for replacement in replacements {
            result = result.replacingOccurrences(
                of: replacement.old,
                with: replacement.new
            )
        }
    } else if option == .backward {
        let replacements: [(old: String, new: String)] = [
            ("Æ", "["),
            ("Ø", "]"),
            ("Å", "}")
        ]
        for replacement in replacements {
            result = result.replacingOccurrences(
                of: replacement.old,
                with: replacement.new
            )
        }
    }
    
    return result
}

