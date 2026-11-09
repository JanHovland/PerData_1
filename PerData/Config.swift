//
//  Config.swift
//

enum Config {
    /// iCloud container identifier.
    static let containerIdentifier = "iCloud.com.janhovland.PerData"
}

///
/// I understand that all schema information in the development environment will be replaced after importing this schema.
///

/// Lag en  Security Role som heter "admin" og har avhuking på:
///     Create, Read og Write
///
/// Gå inn på denne og * legg til de tabellene som skal ha de tilgangene.
/// Ved eksport av Schema fil du se dette for aktuelle tabeller:
/// GRANT READ, CREATE, WRITE TO admin
///
/// **NB. IKKE LEGG DETTE INN I "DEFINE SCHEMA", DET MEDFØRER FEILMELDING!
///

///
/// Nå bruker jeg jeg :
/// database = CKContainer(identifier: Config.containerIdentifier).privateCloudDatabase
///

