//
//  ZipCodeZoom.swift
//  PerData
//
//  Created by Jan Hovland on 24/11/2026.
//

import SwiftUI
import UniformTypeIdentifiers


import SwiftUI

struct Postnummer: Identifiable {
    let postnummer: String
    let poststed: String
    let kommunenummer: String
    let kommune: String
    let posttype: String

    var id: String {
        postnummer + posttype
    }
}

struct ZipCodeZoom: View {

    @State private var searchText = "VÅLER I ØSTFOLD"
    @State private var results: [Postnummer] = []
    @State private var errorMessage = ""

    var body: some View {

        NavigationStack {

            VStack(spacing: 15) {

                // Søkefelt
                HStack {

                    TextField(
                        "Søk etter poststed",
                        text: $searchText
                    )
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit {
                        search()
                    }

                    Button {
                        search()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                    }
                }

                // Feilmelding
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                // Antall treff
                HStack {
                    Text("\(results.count) treff")
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                // Resultater
                List(results) { item in
                    HStack(spacing: 0) {
                        Text(item.postnummer)
                            .frame(width: 55, alignment: .leading)

                        let a = item.poststed.replacingOccurrences(of: "[", with: "Æ")
                        let b = a.replacingOccurrences(of: "]", with: "Ø")
                        let c = b.replacingOccurrences(of: "}", with: "Å")

                        Text(c)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.posttype)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .font(.system(.body, design: .monospaced))
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Postnummer")
            .task {
                search()
            }
        }
    }

    // MARK: - Søk

    private func search() {

        results = []
        errorMessage = ""

        let a = searchText.replacingOccurrences(of: "Æ", with: "[")
        let b = a.replacingOccurrences(of: "Ø", with: "]")
        let c = b.replacingOccurrences(of: "Å", with: "}")
        
        let searchValue = c // searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !searchValue.isEmpty else {
            return
        }

        guard let fileURL = Bundle.main.url(
            forResource: "Post",
            withExtension: "txt"
        ) else {
            errorMessage = "Fant ikke Post.txt"
            return
        }

        do {

            let data = try Data(contentsOf: fileURL)

            print("Filstørrelse:", data.count, "bytes")

            // Les UTF-8. Ugyldige byteverdier erstattes.
            let content = String(
                decoding: data,
                as: UTF8.self
            )

            print(content)
            
            let lines = content.components(separatedBy: "\r\n") //.newlines)
            
            print(lines)

            print("Antall linjer:", lines.count)

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

            print("Antall treff:", results.count)

            if results.isEmpty {
                errorMessage = "Ingen treff funnet"
            }

        } catch {

            errorMessage = "Feil ved lesing av filen"

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
        
//        if columns[1] == "VÅLER" {
//            print(columns[1])
//        }
//        
        return Postnummer(
            postnummer: columns[0],
            poststed: columns[1],
            kommunenummer: columns[2],
            kommune: columns[3],
            posttype: columns[4]
        )
    }
}

//
//  ZipCode.swift
//  PerData
//
//  Created by Jan Hovland on 29/10/2021.
//

import SwiftUI
import CloudKit

/// struct ZipCoder: Identifiable {
struct ZipCode: Identifiable {
   var id = UUID()
   var recordID: CKRecord.ID?
   var postalNumber: String = ""
   var postalName: String = ""
   var municipalityNumber: String = ""
   var municipalityName: String = ""
   var category: String = ""
}



@MainActor
func updatePostNummerFromCSV() async -> LocalizedStringKey {
    
    var index = 0

    /// Finner URL fra prosjektet
    guard let contentsOfURL = Bundle.main.url(forResource: "Post", withExtension: "txt") else { return "Zip file is missing!" }
    /// Må bruke encoding == ascii (utf8 virker ikke)
    let zipCodes = ParseCSV (contentsOfURL: contentsOfURL,
                              delimiter: "    ")
    let maxNumber =  zipCodes!.count
    repeat {
        let zipCode = zipCodes![index]
//        await _ = saveZipCode(zipCode)
        index += 1
        print(index)
    } while index < maxNumber
    let message = LocalizedStringKey("Number of ZipCode saved: \(index)")
    return message
}

func ParseCSV (contentsOfURL: URL,
               delimiter: String) -> [(ZipCode)]? {
    
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
    
    var zipCode: ZipCode! = ZipCode()
    var zipCodes: [(ZipCode)]?
    
    do {
        let content = try String(contentsOf: contentsOfURL, encoding: .ascii)
        
        zipCodes = []
        let lines: [String] = content.components(separatedBy: .newlines)
        for line in lines {
            var values:[String] = []
            if line != "" {
                values = line.components(separatedBy: delimiter)
                zipCode.postalNumber = values[0]
                zipCode.postalName = values[1]
                zipCode.municipalityNumber = values[2]
                zipCode.municipalityName = values[3]
                zipCode.category = values[4]
                zipCodes?.append(zipCode)
            }
        }
    } catch {
        let _ = error.localizedDescription
    }
    return zipCodes
}

func replaceCharacters(in fileURL: URL) -> URL {

    var path = fileURL.path

    let replacements: [(old: String, new: String)] = [
        ("∆", "["),
        ("ÿ", "]"),
        ("≈", "}"),
        ("¡", "O")
    ]

    for replacement in replacements {
        path = path.replacingOccurrences(
            of: replacement.old,
            with: replacement.new
        )
    }

    return URL(fileURLWithPath: path)
}



/*

struct ZipCodeZoom: View {
    
    @State private var searchText = "VÅLER I ØSTFOLD"
    @State private var results: [String] = []
    @State private var errorMessage = ""
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 15) {
                
                HStack {
                    TextField("Søk etter poststed", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onSubmit {
                            search()
                        }
                    
                    Button {
                        search()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                
                Text("\(results.count) treff")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                List(results, id: \.self) { line in
                    
                    let columns = line.components(separatedBy: "\t")
                    
                    if columns.count == 5 {
                        
                        HStack(spacing: 0) {
                            
                            Text(columns[0])
                                .frame(width: 55, alignment: .leading)
                            
                            Text(columns[1])
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(columns[2])
                                .frame(width: 50, alignment: .trailing)
                        }
                        .font(.system(.body, design: .monospaced))
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Postnummer")
            .onAppear {
                search()
            }
        }
    }
    
    // MARK: - Search
    
    private func search() {
        
        results = []
        errorMessage = ""
        
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        guard let fileURL = Bundle.main.url(
            forResource:  "Postnummerregister-ansi_old", //"Postnummer",
            withExtension: "txt"
//            subdirectory: "ZipCode"
        ) else {
            errorMessage = "Fant ikke Postnummer.txt"
            return
        }
        
        results = findPoststed(searchText, in: fileURL)
        
        let r = results
        
        if results.isEmpty {
            errorMessage = "Ingen treff funnet"
        }
    }
}

// MARK: - Find Poststed

func findPoststed(_ searchText: String, in fileURL: URL) -> [String] {

    do {
        let data = try Data(contentsOf: fileURL)

        print("Filstørrelse:", data.count, "bytes")
        
        let content = String(decoding: data, as: UTF8.self)

//        guard let content = String(
//            data: data,
//            encoding: .macOSRoman
//        ) else {
//            print("Kunne ikke lese filen")
//            return []
//        }

        let lines = content.components(separatedBy: .newlines)

        print("Antall linjer:", lines.count)
        
//        for line in lines { // where line.contains("1592") {
//            let columns = line.components(separatedBy: "\t")
//
//            print("Hele linjen:", line)
//            print("Antall kolonner:", columns.count)
//
//            if columns.count > 1 {
//                print("Poststed:", "[\(columns[1])]")
//                print(
//                    "Sammenligning:",
//                    columns[1].localizedCaseInsensitiveContains("VÅLER I ØSTFOLD")
//                )
//            }
//        }
 
        return lines.filter { line in

            let columns = line.components(separatedBy: "\t")

//            print(columns)
            
            
            guard columns.count == 8 else { // 5 else {
                return false
            }

            let poststed = columns[1]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if poststed .contains("VÅLER I ØSTFOLD") {
                
                
                print(poststed)
            }

            return poststed.localizedCaseInsensitiveContains("VÅLER I ØSTFOLD"
            )
        }

    } catch {
        print("Lesefeil:", error.localizedDescription)
        return []
    }
}
*/


/*
 
 @MainActor
 func updatePostNummerFromCSV() async -> LocalizedStringKey {
     
     let index = 0
 //
 //    /// Finner URL fra prosjektet
 //    guard let contentsOfURL = Bundle.main.url(forResource: "Postnummerregister-ansi", withExtension: "txt") else { return "Zip file is missing!" }
 //    /// Må bruke encoding == ascii (utf8 virker ikke)
 //    let zipCodes = ParseCSV (contentsOfURL: contentsOfURL,
 //                              delimiter: "    ")
 //    let maxNumber =  zipCodes!.count
 //    repeat {
 //        let zipCode = zipCodes![index]
 //        await _ = saveZipCode(zipCode)
 //        index += 1
 //        print(index)
 //    } while index < maxNumber
     let message = LocalizedStringKey("Number of ZipCode saved: \(index)")
     return message
 }
 
 
 
 func ParseCSV (contentsOfURL: URL,
                delimiter: String) -> [(ZipCode)]? {
     
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
     
     var zipCode: ZipCode! = ZipCode()
     var zipCodes: [(ZipCode)]?
     
     do {
         let content = try String(contentsOf: contentsOfURL, encoding: .ascii)
         
         zipCodes = []
         let lines: [String] = content.components(separatedBy: .newlines)
         for line in lines {
             var values:[String] = []
             if line != "" {
                 values = line.components(separatedBy: delimiter)
                 zipCode.postalNumber = values[0]
                 zipCode.postalName = values[1]
                 zipCode.municipalityNumber = values[2]
                 zipCode.municipalityName = values[3]
                 zipCode.category = values[4]
                 zipCodes?.append(zipCode)
             }
         }
     } catch {
         let _ = error.localizedDescription
     }
     return zipCodes
 }
 */
