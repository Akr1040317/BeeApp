// QuizzesView.swift

import SwiftUI

struct QuizzesView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: EnglishQuizView()) {
                    Text("English Quiz")
                }
                NavigationLink(destination: SpanishQuizView()) {
                    Text("Spanish Quiz")
                }
                NavigationLink(destination: FrenchQuizView()) {
                    Text("French Quiz")
                }
                NavigationLink(destination: GermanQuizView()) {
                    Text("German Quiz")
                }
                NavigationLink(destination: ItalianQuizView()) {
                    Text("Italian Quiz")
                }
            }
            .navigationTitle("Quizzes")
        }
    }
}

