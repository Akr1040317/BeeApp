
// ProfileView.swift

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
       @State private var navigateToQuizzes = false


    var body: some View {
        if let user = viewModel.currentUser {
            NavigationStack {
                List {
                    // ... Other sections ...
                    Section {
                        HStack {
                            Text(user.initials)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Col1"))
                                .frame(width: 72, height: 72)
                                .background(Color(.systemGray3))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullname)
                                    .fontWeight(.semibold)
                                    .padding(.top, 4)

                                Text(user.email)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Section("General"){
                        HStack {
                            SettingsRowView(imageName: "gear", title: "Version", tintColor: Color(.systemGray))
                            Spacer()

                            Text("1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Section("Account"){
                        Button{
                            viewModel.signOut()
                        } label: {
                            SettingsRowView(imageName: "arrow.left.circle.fill", title: "Sign Out", tintColor: .red)
                        }

                        Button{
                            print("Delete account..")
                        } label: {
                            SettingsRowView(imageName: "xmark.circle.fill", title: "Delete Account", tintColor: .red)
                        }
                    }

                    Section("Quizzes") {
                        Button(action: {
                            self.navigateToQuizzes = true
                        }) {
                            Text("Take Quizzes")
                        }
                        .background(
                            NavigationLink("", destination: QuizzesView(), isActive: $navigateToQuizzes)
                                .opacity(0)
                        )
                    }
                }
            }
        }
    }
}


struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}

