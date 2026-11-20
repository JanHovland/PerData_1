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

struct PersonView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var person: Person
    
    @State private var message: LocalizedStringKey = ""
    @State private var title: LocalizedStringKey = ""
    @State private var isAlertActive = false
    @State private var image = UIImage()
    @State private var saveImage: Bool = false
    
    @State private var showImage = false
    @State private var modifyImage = false
    @State private var showDeseased = false

    var genders = [String(localized: "Man"),
                   String(localized: "Woman")]
    
    var body: some View {
        NavigationView {
            VStack {

                Group {
                    ZStack {
                        if person.image != nil {
                            Image(uiImage: person.image!)
                                .resizable()
                                .frame(width: 80, height: 80, alignment: .center)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .onTapGesture {
                                    showImage.toggle()
                                    modifyImage = false
                                }
                        } else {
                            ZStack {
                                Text("Select\nimage")
                                    .font(Font.footnote.weight(.medium))
                                    .foregroundColor(.green)
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 80, height: 80, alignment: .center)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                    .onTapGesture {
                                        showImage.toggle()
                                        modifyImage = true
                                    }
                            }
                        }
                    }
                    .sheet(isPresented: $showImage, content: {
                        ImagePicker(sourceType: .photoLibrary, selectedImage: $image, image: $person.image)
                    })
                    
                    Grid {
                        GridRow {
                            if showDeseased {
                                Text("Alive")
                                    .bold()
                                DeseasedPicker(
                                    isDeseased: Binding<Bool>(
                                        get: {
                                            person.dead == 1
                                        },
                                        set: { newValue in
                                            person.dead = newValue ? 1 : 0
                                        }
                                    )
                                )
                                .padding(.leading, 15)
                            }
                        }
                        .gridColumnAlignment(.leading)
                        .padding(.top, 2.5)
                        
                        GridRow {
                            Text("FirstName")
                                .bold()
                            TextField("FirstName", text: $person.firstName)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("LastName")
                                .bold()
                            TextField("LastName", text: $person.lastName)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("Email")
                                .bold()
                            TextField("Email", text: $person.personEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("Address")
                                .bold()
                            TextField("Address", text: $person.address)
                                .autocapitalization(.words)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("Phonenumber")
                                .bold()
                            TextField("Phonenumber", text: $person.phoneNumber)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("Gender")
                                .bold()
                            GenderPicker(
                                selection: Binding<Gender>(
                                    get: {
                                        // Map stored Int to Gender enum (default to .male)
                                        switch person.gender {
                                        case 1: return .female
                                        default: return .male
                                        }
                                    },
                                    set: { newValue in
                                        // Map Gender enum back to stored Int
                                        switch newValue {
                                        case .male: person.gender = 0
                                        case .female: person.gender = 1
                                        }
                                    }
                                )
                            )
                            .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        .padding(.top, 2.5)
                    }
                }

                Group {
                    HStack(alignment: .center, spacing: 10) {
                        TextField("Citynumber", text: $person.cityNumber)
                            .keyboardType(.numberPad)
                        TextField("City", text: $person.city)
                            .autocapitalization(.allCharacters)
                    }
                    HStack(alignment: .center, spacing: 0) {
                        TextField("Municipality number", text: $person.municipalityNumber)
                            .keyboardType(.numberPad)
                        TextField("Municipality", text: $person.municipality)
                            .autocapitalization(.none)
                            .autocapitalization(.words)
                    }
                    Grid {
                        GridRow {
                            HStack {
                                DatePicker(
                                    selection: $person.dateOfBirth,
                                    in: ...Date(),
                                    displayedComponents: [.date],
                                    label: {
                                        Text("Date of birth")
                                    }
                                )
                                Spacer()
                            }
                            .padding(.trailing, UIDevice.isIpad ? 275 : 100)
                        }
                        .gridColumnAlignment(.leading)
                    }
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

