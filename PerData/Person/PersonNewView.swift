//
//  PersonNewView.swift
//  PerData
//
//  Created by Jan Hovland on 27/10/2021.
//

import CloudKit
import SwiftUI

//
// https://developer.apple.com/videos/play/wwdc2021/10023/
// This one is about focus
//
// https://www.hackingwithswift.com/articles/216/complete-guide-to-navigationview-in-swiftui
//

struct PersonNewView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var person: Person
    
    @State private var message: LocalizedStringKey = ""
    @State private var title: LocalizedStringKey = ""
    @State private var isAlertActive = false
    @State private var image = UIImage()
    @State private var saveImage: Bool = false
    
    @State private var showImage = false
    @State private var showDeseased = true

    var genders = [String(localized: "Man"),
                   String(localized: "Woman")]
    
    var body: some View {
        NavigationView {
            VStack {
                Group {
                    PersonForm(person: $person,
                               showImage: $showImage,
                               image: $image,
                               showDeseased: $showDeseased)
                }
                Spacer()
            }
            .padding()
            .textFieldStyle(.roundedBorder)
            .navigationBarTitle("New person", displayMode: .inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ControlGroup {
                        Button(action: {
                            if person.firstName.count > 0,
                               person.lastName.count > 0
                            {
                                //
                                // Sjekk om posten finnes i CloudKit.
                                // Save hvis den ikke finnes
                                //
                                
                                // predicate
                                
                                
                                if person.recordID != nil {
                                    title = "Person exists"
                                    message = "Person already exists"
                                    isAlertActive.toggle()
                                } else {
                                    message = "A new Person"
                                    title = "New person"
                                    isAlertActive.toggle()
                                    
                                    Task {
                                        await _ = save(person)
                                    }
                                    
                                }
                            } else {
                                title = "Missing values."
                                message = "First- and LastName must both have values."
                                isAlertActive.toggle()
                            }
                            
                            
                            
                        }, label: {
                            Text("Save")
                        })
                        .alert(title, isPresented: $isAlertActive) {
                            Button("OK", action: {})
                        } message: {
                            Text(message)
                        }
                    }
                    .controlGroupStyle(.navigation)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    ControlGroup {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            ReturnFromMenuView(text: "PersonOverView")
                        }
                    }
                    .controlGroupStyle(.navigation)
                }
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
     }
}

