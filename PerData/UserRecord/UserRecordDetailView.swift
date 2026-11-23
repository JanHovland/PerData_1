//
//  UserRecordDetailView.swift
//  PerData
//
//  Created by Jan Hovland on 22/11/2021.
//

import CloudKit
import SwiftUI

struct UserRecordDetailView: View {
    @State var userRecord: UserRecord

    @Environment(\.presentationMode) var presentationMode

    @State private var showImage = false
    @State private var isAlertActive = false
    @State private var indicatorShowing = false

    @State private var title: LocalizedStringKey = ""
    @State private var message: LocalizedStringKey = ""

    @State private var image = UIImage()

    @State private var recordID: CKRecord.ID?

    var body: some View {
        VStack {
            ZStack {
                if userRecord.image != nil {
                    Image(uiImage: userRecord.image!)
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
                ImagePicker(sourceType: .photoLibrary, selectedImage: $image, image: $userRecord.image)
            })

            .padding(.top, 25)
            VStack {
                Group {
                    Grid {
                        GridRow {
                            Text("FirstName")
                                .bold()
                            TextField("FirstName", text: $userRecord.firstName)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("LastName")
                                .bold()
                            TextField("LastName", text: $userRecord.lastName)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("Email")
                                .bold()
                            TextField("Email", text: $userRecord.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                        
                        GridRow {
                            Text("PassWord")
                                .bold()
                            SecureField("PassWord", text: $userRecord.passWord)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.leading, 15)
                        }
                        .gridColumnAlignment(.leading)
                    }
                }
            }
            ///
            /// Gir svart bakgrunn på TextField og SecureField
            ///

            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 20)
            Spacer()
        }
        .navigationBarTitle("User Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            if userRecord.firstName.count > 0,
                               userRecord.lastName.count > 0,
                               userRecord.email.count > 0,
                               userRecord.passWord.count > 0
                            {
                                indicatorShowing = true
                                message = await modifyUserRecord(userRecord)
                                title = "Modify userRecord"
                                isAlertActive.toggle()
                                indicatorShowing = false
                            } else {
                                title = "Missing value(s)"
                                message = "All the fields must have a value"
                                isAlertActive.toggle()
                            }
                        }
                    } label: {
                        Label("Update", systemImage: "square.and.pencil")
                    }
                    
                    Menu {
                        Menu {
                            Button (role: .destructive) {
                                Task {
                                    if userRecord.recordID != nil {
                                        message = await deleteUserRecord(userRecord.recordID!)
                                        message = "This user is deleted"
                                        userRecord = UserRecord(firstName: "",
                                                                lastName: "",
                                                                email: "",
                                                                passWord: "")
                                        userRecord.image = nil
                                        title = "Delete a user"
                                        isAlertActive.toggle()
                                    } else {
                                        title = "Delete a user"
                                        message = "Can not delete a user without a record ID."
                                        isAlertActive.toggle()
                                    }
                                }
                            } label: {
                                Label("Delete a user", systemImage: "trash")
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
                        Label("Delete a user", systemImage: "trash")
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
