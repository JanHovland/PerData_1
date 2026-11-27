//
//  PersonForm.swift
//  PerData
//
//  Created by Jan Hovland on 21/11/2026.
//

import SwiftUI

struct PersonForm: View {
    @Binding var person: Person
    @Binding var showImage: Bool
    @Binding var image: UIImage
    @Binding var showDeseased: Bool
    
    var body: some View {
        VStack {
            ZStack {
                if person.image != nil {
                    Image(uiImage: person.image!)
                        .resizable()
                        .frame(width: 80, height: 80, alignment: .center)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        .onTapGesture {
                            showImage.toggle()
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
                    Text("ZipCode")
                        .bold()
                    HStack(spacing: 10) {
                        TextField("cityNumber", text: $person.cityNumber)
                            .frame(width: 60)
                            .autocapitalization(.words)
                        TextField("City", text: $person.city)
                            .autocapitalization(.words)
                            .frame(width: .infinity)
                    }
                    .padding(.leading, 10)
                }
                
                GridRow {
                    Text("Municipality")
                        .bold()
                    HStack(spacing: 10) {
                        TextField("municipalityNumber", text: $person.municipalityNumber)
                            .frame(width: 60)
                            .autocapitalization(.words)
                        TextField("municipality", text: $person.municipality)
                            .autocapitalization(.words)
                            .frame(width: .infinity)
                    }
                    .padding(.leading, 10)
                }

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
                Group {
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
                            .padding(.trailing, UIDevice.isIpad ? 319 : 140)
                        }
                        .gridColumnAlignment(.leading)
                    }
                }
                .gridColumnAlignment(.leading)
                .padding(.top, 2.5)
            }
        }
        .padding(.top, 10)
    }
}
