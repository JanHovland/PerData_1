//
//  PersonUpdateView.swift
//  PerData
//
//  Created by Jan Hovland on 27/10/2021.
//

import CloudKit
import SwiftUI

//
// https://www.simpleswiftguide.com/swiftui-textfield-complete-tutorial/
// https://www.hackingwithswift.com/articles/216/complete-guide-to-navigationview-in-swiftui
//

struct PersonUpdateView: View {
    // Denne kalles via NavigationLink i PerData som innholder automatisk retur.
    // Derfor må det ikke legge inn NavigationView.
    
    @State var person: Person
    @State private var message: LocalizedStringKey = ""
    @State private var title: LocalizedStringKey = ""
    @State private var isAlertActive = false
    @State private var image = UIImage()
    @State private var modifyImage = false
    @State private var showImage = false
    @State private var recordID: CKRecord.ID?
    @State private var showDeseased = false
    
    @Environment(\.presentationMode) var presentationMode
    
    struct Dead: Hashable, Identifiable {
        var id = UUID()
        var isDead = false
        var name = ""
    }
    
    var genders = [String(localized: "Man"),
                   String(localized: "Woman")]
    
    var death = [String(localized: "No"),
                 String(localized: "Yes")]
    
    var body: some View {
        VStack(spacing: 10) {
            //
            // VStack kan kun inneholde 10 elementer,
            // derfor må Group benyttes
            //
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
        .textFieldStyle(.roundedBorder)
        .padding()
        .navigationBarTitle("Modify person", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            if person.recordID != nil {
                                showDeseased = true
                            }
                        }
                    } label: {
                        Label("Show deseased", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    
                    Button {
                        Task {
                            if person.recordID != nil {
                                message = await modify(person, modifyImage)
                                modifyImage = false
                                title = "Modify"
                                isAlertActive.toggle()
                            }
                        }
                    } label: {
                        Label("Modify", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    }

                    Menu {
                        Menu {
                            Button (role: .destructive) {
                                Task {
                                    if person.recordID != nil {
                                        message = await deletePerson(person.recordID!)
                                        message = "sletter person"
                                        person = Person()
                                        person.image = nil
                                        title = "Delete a person"
                                        isAlertActive.toggle()
                                    } else {
                                        title = "Delete a person"
                                        message = "Can not delete a person without a record ID."
                                        isAlertActive.toggle()
                                    }
                                }
                            } label: {
                                Label("Delete a person", systemImage: "trash")
                            }
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Label("Cancel", systemImage: "xmark")
                            }
                        } label: {
                            Label("Confirm delete", systemImage: "questionmark.app")
                        }
                        
                    } label: {
                        Label("Delete a person", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.accentColor)
                        .font(.body.weight(.regular))
                }
            }
        }
        .alert(title, isPresented: $isAlertActive) {
            Button("OK", action: { presentationMode.wrappedValue.dismiss() })
        } message: {
            Text(message)
        }
    }
}

enum Gender: String, CaseIterable, Identifiable {
    case male = "Mann"
    case female = "Kvinne"

    var id: Self {
        self
    }
}

struct GenderPicker: View {
    @Binding var selection: Gender

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Gender.allCases) { item in
                Button {
                    selection = item
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName:
                            selection == item
                                ? "largecircle.fill.circle"
                                : "circle")
                            .foregroundStyle(.blue)

                        Text(item.rawValue)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DeseasedPicker: View {
    @Binding var isDeseased: Bool
    
    var body: some View {
        Button {
            isDeseased.toggle()
        } label: {
            Label {
                Text("Deseased")
            } icon: {
                Image(systemName:
                    isDeseased
                        ? "checkmark.square.fill"
                        : "square")
                    .foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
    }
}

