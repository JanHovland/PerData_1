//
//  PersonData.swift
//  PerData
//
//  Created by Jan Hovland on 30/11/2021.
//

//
//  Comment: Control + Command + * (number keyboard)
//  Indent:  Control + Command + / (number keyboard)
//

// https://peterfriese.dev/swiftui-concurrency-essentials-part1/
// https://peterfriese.dev/swiftui-listview-part3/
// https://stackoverflow.com/questions/57888032/swiftui-navigation-on-ipad-how-to-show-master-list
//
// https://sarunw.com/posts/how-to-present-alert-in-swiftui-ios15/

//     For å få frem lokalt navn på appen:
//
//     TARGETS under Info:
//     Bundle name må være $(PRODUCT_NAME)
//     Bundle identifier må være $(PRODUCT_BUNDLE_IDENTIFIER)
//     Legg til:
//         Application has localized display name
//

//
// iOS 15 Brings Attributed Strings to SwiftUI:
// https://betterprogramming.pub/ios-15-attributed-strings-in-swiftui-markdown-271204bec5c1
//

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-search-bar-to-filter-your-data

import CloudKit
import Network
import SwiftUI

/*
 MainActor is a new attribute introduced in Swift 5.5 as a global actor providing an executor which performs its tasks on the main thread. When building apps, it’s important to perform UI updating tasks on the main thread, which can sometimes be challenging when using several background threads. Using the @MainActor attribute will help you make sure your UI is always updated on the main thread.
 */

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-a-menu-when-a-button-is-pressed

//
// A brief explanation of the basics of SwiftUI
// https://www.hackingwithswift.com/quick-start/swiftui/
//

//
// Status Code Definitions for Hypertext Transfer Protocol -- HTTP/1.1
// https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
//

//
// Custom SwiftUI Environment Values Cheatsheet https://www.fivestars.blog/articles/custom-environment-values-cheatsheet/?utm_campaign=%20SwiftUI%20Weekly&utm_medium=email&utm_source=Revue%20newsletter
//

//
// `Har kommnentert bort innholdet i ** func updatePostNummerFromCSV()
// *for å hindre en ekstra oppdatering av ZioCode  tabellen
//
// **bold text**
// *italics* eller _
// ~~strikethrough~~
// `inline code`
//  /// [Hyperlinks](https://hyperlink.com)

//
// Text("To **learn more**, *please* feel free to visit [SwiftUIRecipes](https://swiftuirecipes.com) for details, or check the `source code` at [Github page](https://github.com/globulus).")
//

@MainActor

struct PersonData: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var message: LocalizedStringKey = ""
    @State private var title: LocalizedStringKey = ""
    
    @State private var searchText = ""
    
    @State var person = Person()
    @State var personNew = Person()
    @State private var persons = [Person]()
    @State private var indexSetDelete = IndexSet()
    @State private var recordID: CKRecord.ID?
    
    @State private var menuShowNewPersonSheet = false
    
    let internetMonitor = NWPathMonitor()
    let internetQueue = DispatchQueue(label: "InternetMonitor")
    @State private var hasConnectionPath = false
    @State private var device: LocalizedStringKey = ""
    
    //
    // Menyen
    //
    
    @State private var menuToDo = false
    @State private var menuBirthDay = false
    @State private var menuCabin = false
    @State private var menuUserRecordView = false
    @State private var menuUpdatePersonsFromJsonBackupFileView = false
    @State private var menuBackupPersonsToJsonBackupFileView = false
    
    @State private var menuUpdateUserRecordsFromJsonBackupFileView = false
    @State private var menuBackupUserRecordsToJsonBackupFileView = false
    
    @State private var menuUpdateCabinsFromBackupFileView = false
    @State private var menuBackupCabinsToJsonBackupFileView = false
    
    @State private var indicatorShowing = false
    @State private var isAlertActive = false
    
    @State private var sectionHeader = [String]()
    @State private var predicate = NSPredicate(value: true)
    
    
    @State private var option: EnumType = .new

    var body: some View {
        NavigationStack {
            VStack {
                if indicatorShowing {
                    ActivityIndicator(isAnimating: $indicatorShowing, style: .medium, color: .gray)
                }
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading) {
                        ForEach(persons) { person in
                            if searchText == "" || person.firstName.uppercased().contains(searchText.uppercased()) {
                                NavigationLink(destination: PersonUpdateView(person: person)) {
                                    VStack(alignment: .leading) {
                                        PersonDetailView(person: person)
                                        HStack(spacing: UIDevice.isIpad ? 60 : 30) {
                                            PersonDetailMapView(person: person)
                                            PersonDetailPhoneView(person: person)
                                            PersonDetailMessageView(person: person)
                                            PersonDetailMailView(person: person)
                                            PersonDetailCabinView(person: person)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSetDelete = indexSet
                            recordID = persons[indexSet.first!].recordID
                            persons.removeAll()
                            Task {
                                await message = deletePerson(recordID!)
                                title = "Delete a person"
                                isAlertActive.toggle()
                                //
                                // Viser resten av personene
                                //
                                await refreshPersonsIndexed(predicate: predicate)
                            }
                        }
                        .padding(.bottom, 10)
                        .gradientGlass()
                    } // VStack
                    .padding(.horizontal, UIDevice.isIpad ? 20 : 20)
                } // ScrollView
            }
            .alert(title, isPresented: $isAlertActive) {
                Button("OK", action: {})
            } message: {
                Text(message)
            }
            .task {
                indicatorShowing = true
                await refreshPersonsIndexed(predicate: predicate)
                indicatorShowing = false
            }
            .navigationBarTitle("PersonOverView", displayMode: .inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    ControlGroup {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            ReturnFromMenuView(text: "SignInView")
                        }
                    }
                    .controlGroupStyle(.navigation)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await refreshPersonsIndexed(predicate: predicate)
                            }
                        } label: {
                            Label("Refresh", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            menuShowNewPersonSheet.toggle()
                        } label: {
                            Label("New person", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            menuUserRecordView.toggle()
                        } label: {
                            Label("UserRecords", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            menuBirthDay.toggle()
                        } label: {
                            Label("Birthdays", systemImage: "gift")
                        }
                        
                        Button {
                            menuCabin.toggle()
                        } label: {
                            Label("Cabin reservation", systemImage: "house")
                        }
                        
                        Button {
                            menuToDo.toggle()
                        } label: {
                            Label("ToDo", systemImage: "list.dash.header.rectangle")
                        }
                        
                        Menu {
                            Menu {
                                Button {
                                    menuUpdateUserRecordsFromJsonBackupFileView.toggle()
                                } label: {
                                    Label("From Json", systemImage: "square.and.pencil")
                                }
                                Button {
                                    menuBackupUserRecordsToJsonBackupFileView.toggle()
                                } label: {
                                    Label("To Json", systemImage: "square.and.pencil")
                                }
                            } label: {
                                Label("UserRecord", systemImage: "questionmark.app")
                            }
                            
                            Menu {
                                Button {
                                    menuUpdatePersonsFromJsonBackupFileView.toggle()
                                } label: {
                                    Label("From Json", systemImage: "square.and.pencil")
                                }
                                Button {
                                    menuBackupPersonsToJsonBackupFileView.toggle()
                                } label: {
                                    Label("To Json", systemImage: "square.and.pencil")
                                }
                            } label: {
                                Label("Person", systemImage: "questionmark.app")
                            }
                            
                            Menu {
                                Button {
                                    menuUpdateCabinsFromBackupFileView.toggle()
                                } label: {
                                    Label("From Json", systemImage: "square.and.pencil")
                                }
                                Button {
                                    menuBackupCabinsToJsonBackupFileView.toggle()
                                } label: {
                                    Label("To Json", systemImage: "square.and.pencil")
                                }
                            } label: {
                                Label("Cabin reservation", systemImage: "questionmark.app")
                            }
                            
                        } label: {
                            Label("Store/Restore", systemImage: "questionmark.app")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.accentColor)
                            .font(Font.body.weight(.regular))
                    }
                    .sheet(isPresented: $menuToDo, content: {
                        toDoView()
                    })
                    .sheet(isPresented: $menuBirthDay, content: {
                        personBirthdayView()
                    })
                    .sheet(isPresented: $menuCabin, content: {
                        CabinOverView()
                    })
                    .sheet(isPresented: $menuUpdatePersonsFromJsonBackupFileView, content: {
                        updatePersonsFromJsonBackupFileView()
                    })
                    .sheet(isPresented: $menuBackupPersonsToJsonBackupFileView, content: {
                        backupPersonsToJsonBackupFileView()
                    })
                    .sheet(isPresented: $menuUserRecordView, content: {
                        UserData()
                    })
                    .sheet(isPresented: $menuBackupUserRecordsToJsonBackupFileView, content: {
                        backupUserRecordsToJsonBackupFileView()
                    })
                    .sheet(isPresented: $menuUpdateUserRecordsFromJsonBackupFileView, content: {
                        updateUserRecordsFromJsonBackupFileView()
                    })
                    
                    .sheet(isPresented: $menuBackupCabinsToJsonBackupFileView, content: {
                        backupCabinsToJsonBackupFileView()
                    })
                    
                    .sheet(isPresented: $menuUpdateCabinsFromBackupFileView, content: {
                        updateCabinsFromJsonBackupFileView()
                    })
                    
                    .sheet(isPresented: $menuShowNewPersonSheet, content: {
                        PersonNewView(person: person)
                    })
                }
                
            })
            .listStyle(.insetGrouped)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search firstName")
        .onChange(of: searchText.capitalized) { _, searchText in
            predicate = searchText.isEmpty ? NSPredicate(value: true) : NSPredicate(format: "firstName BEGINSWITH %@", searchText)
            Task {
                indicatorShowing = true
                await refreshPersonsIndexed(predicate: predicate)
                indicatorShowing = false
            }
        }
        .refreshable {
            Task {
                await refreshPersonsIndexed(predicate: predicate)
            }
        }
    }
    
    func refreshPersonsIndexed(predicate: NSPredicate) async {
        // Sletter alt tidligere innhold i persons
        persons.removeAll()
        sectionHeader.removeAll()
        // Fetch all userRecords from CloudKit
        var value: (LocalizedStringKey, [Person], [String])
        await value = findPersons(predicate: predicate)
        if value.0 != "" {
            message = value.0
            title = "Error message from the Server"
            isAlertActive.toggle()
        } else {
            persons = value.1
            ///
            /// Først en enkel sortering for stabilitet
            ///
            persons.sort { lhs, rhs in
                lhs.firstName.localizedCaseInsensitiveCompare(rhs.firstName) == .orderedAscending
            }
            ///
            /// Norsk (lokal) sortering av fornavn ved bruk av Locale
            ///
            let region = NSLocale.current.region?.identifier.lowercased()
            let locale = region.flatMap { Locale(identifier: $0) } ?? Locale.current
            persons = persons.sorted { lhs, rhs in
                lhs.firstName.compare(rhs.firstName, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: locale) == .orderedAscending
            }
            sectionHeader = value.2
        }
    }
    
}
