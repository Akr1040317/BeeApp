import SwiftUI

struct ItalianQuizView: View {
    @State private var answer = ""

    var body: some View {
        VStack {
            Text("Italian Quiz")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            // Display the word to spell
            Text("Word to Spell")

            // Input field for the user's answer
            TextField("Enter your answer", text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)

            // Submit button
            Button(action: submitAnswer) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()

            // Display the user's current score
           
        }
    }

    func submitAnswer() {
        // Perform answer validation logic here

        // Update the user's score
   
    }
}

struct ItalianQuizView_Previews: PreviewProvider {
    static var previews: some View {
        ItalianQuizView()
    }
}

