import SwiftUI
import FirebaseFirestore
import Combine
import AVFoundation
import Foundation

extension Color {
    
}

class QuizViewModelSpanish: ObservableObject {
    @Published var questions: [String] = []
    @Published var quizCompleted = false
    @Published var wordInformation: [String: Any] = [:]
    
    
    var score: Int = 0 // Add a score property

    func checkAnswer(answer: String, atIndex index: Int) {
        let correctAnswer = questions[index].replacingOccurrences(of: ":1", with: "").lowercased()
        let userAnswer = answer.lowercased()

        if userAnswer == correctAnswer {
            score += 1
        }
    }
    
    func fetchQuestions(completion: @escaping () -> Void) {
        let db = Firestore.firestore() // initializing database
        db.collection("Quiz").document("SpanishQuiz").getDocument { (snapshot, error) in // searching for the document
            if let error = error {
                print("Failed to fetch questions with error: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("Document does not exist")
                return
            }

            // Extract the question strings from the document
            if let questions = data["Questions"] as? [String] { // get the words from the array in the Quiz collection
                DispatchQueue.main.async {
                    self.questions = questions
                    completion() // Call the completion closure after the questions are fetched
                }
            } else {
                print("No 'Questions' field found in the document")
            }
        }
    }
}

struct SpanishQuizView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var answer = ""
    @State private var fullName: String?
    @State private var userId: String?
    @State private var quizId = "Spanish Quiz"
    @State private var currentQuestionIndex = 0 // Track the current question index
    @State private var compiledAnswers: [String] = []
    @StateObject private var quizViewModel = QuizViewModel()
    @State private var quizCompleted = false
    @State private var wordInformation: [String: Any] = [:] // Hold the word information
    @State private var audioFile = ""
    @State private var audioPlayer: AVPlayer?
    
    

    // AVPlayer for audio playback
    var urlStart: String { "https://media.merriam-webster.com/audio/prons/en/us/mp3/" }
    var urlAbbrev: String { "c" }
    var urlFile: String { "car00001" }
    var urlString: String { urlStart + urlAbbrev + "/" + urlFile + ".mp3" }
        
    
        // Now you can use the 'audioPlayer' object as needed
    
        
    var body: some View {
        let gradientBackground = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "c94b4b"), Color(hex: "4b134f")]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        ZStack{
            gradientBackground // Apply the gradient background to the entire ZStack
                            .edgesIgnoringSafeArea(.all)
            Group{
                if quizCompleted {
                    // Display congratulatory message and score
                    VStack{
                        VStack {
                            Text("Congrats, you have finished this quiz!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                            
                            Text("Your score was: \(quizViewModel.score) out of \(quizViewModel.questions.count)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                            
                            HStack {
                                VStack {
                                    Button(action: restartQuiz) {
                                        Text("Restart Quiz")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                                }
                                
                                Spacer()

                                VStack {
                                    NavigationLink(destination: ProfileView()) {
                                        Text("Go Back to Home")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.green)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    
                    
                } else{
                    VStack {
                        ProgressBar(currentQuestion: currentQuestionIndex, totalQuestions: quizViewModel.questions.count)
                        Text("Spanish Quiz")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()

                        // Display the current question if available
                        if currentQuestionIndex == quizViewModel.questions.count {
                            Text("Quiz Completed!")
                        }

                        // Display word information if available
                        if !wordInformation.isEmpty {
                            ForEach(wordInformation.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                // Exclude the fields you don't want to display
                                if key != "headword" && key != "offensive" && key != "pronunciations" && key != "section" {
                                    VStack(alignment: .leading) {
                                        Text(formatKey(key: key))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(formatValue(value: value))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }

                        // Input field for the user's answer
                        TextField("Enter your answer", text: $answer, onCommit: submitAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .autocapitalization(.none)
                            .onChange(of: currentQuestionIndex) { _ in
                                answer = "" // Reset the answer to an empty string when the question changes
                                //access second index of pronunciations array for the
                            
                                playAudio() // Play audio when moving to the next question
                                let currentWord = quizViewModel.questions[currentQuestionIndex]
                                checkWordExistsInFirestore(word: currentWord) { exists in
                                    if exists {
                                        fetchWordInformation(word: currentWord)
                                    } else {
                                        fetchWordInformationFromAPI(word: currentWord) { wordInformation in
                                            if let wordInformation = wordInformation {
                                                saveWordInformationToFirestore(word: currentWord, wordInformation: wordInformation) {
                                                    print("Word information saved to Firestore for word: \(currentWord)")
                                                    fetchWordInformation(word: currentWord) // Fetch the word information after saving
                                                }
                                            } else {
                                                print("Failed to fetch word information for word: \(currentWord)")
                                            }
                                        }
                                    }
                                }
                            }
                            .disabled(currentQuestionIndex >= quizViewModel.questions.count || quizCompleted) // Disable the input field when quiz is completed

                        // Submit button
                        Button(action: submitAnswer) {
                            Text("Submit")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(currentQuestionIndex >= quizViewModel.questions.count || quizCompleted) // Disable the submit button when quiz is completed
            }
            .onAppear {
                userId = viewModel.currentUser?.id
                quizViewModel.fetchQuestions {
                    // Start playing the audio file
                    initializeAudioPlayer()
                    let currentWord = quizViewModel.questions[currentQuestionIndex]
                    checkWordExistsInFirestore(word: currentWord) { exists in
                        if exists {
                            fetchWordInformation(word: currentWord)
                        } else {
                            fetchWordInformationFromAPI(word: currentWord) { wordInformation in
                                if let wordInformation = wordInformation {
                                    saveWordInformationToFirestore(word: currentWord, wordInformation: wordInformation) {
                                        print("Word information saved to Firestore for word: \(currentWord)")
                                        fetchWordInformation(word: currentWord) // Fetch the word information after saving
                                    }
                                } else {
                                    print("Failed to fetch word information for word: \(currentWord)")
                                }
                            }
                        }
                    }
                }
            }
                }
            }
            
        }
    
    }
    func formatKey(key: String) -> String {
        var formattedKey = key
        if formattedKey.hasSuffix(":1") {
            formattedKey = String(formattedKey.dropLast(2))
        }
        
        switch formattedKey {
        case "id":
            return "Word"
        case "partOfSpeech":
            return "Part of speech"
        case "shortDefinition":
            return "Definition"
        default:
            return formattedKey
        }
    }

    func formatValue(value: Any) -> String {
        if let valueString = value as? String {
            return valueString.replacingOccurrences(of: ":1", with: "")
        } else if let valueArray = value as? [String] {
            return valueArray.joined(separator: ", ")
        } else {
            return ""
        }
    }
    
    func submitAnswer() {
        // Append the answer to the compiled answers array
        compiledAnswers.append(answer)

        quizViewModel.checkAnswer(answer: answer, atIndex: currentQuestionIndex)
        // Move to the next question
        if currentQuestionIndex < quizViewModel.questions.count - 1 {
            currentQuestionIndex += 1
            answer = "" // Clear the answer for the next question
        } else {
            // Quiz completed, handle the end of the quiz
            quizCompleted = true

            // Store the compiled answers in the Firebase database
            Task {
                do {
                    try await viewModel.submitAnswers(answers: compiledAnswers, score: quizViewModel.score, userId: userId, quizId: quizId)
                } catch {
                    print("Failed to submit answers with error: \(error.localizedDescription)")
                }
            }
        }

        // Play audio when moving to the next question
        playAudio()
        let currentWord = quizViewModel.questions[currentQuestionIndex]
        checkWordExistsInFirestore(word: currentWord) { exists in
            if exists {
                fetchWordInformation(word: currentWord)
            } else {
                fetchWordInformationFromAPI(word: currentWord) { wordInformation in
                    if let wordInformation = wordInformation {
                        saveWordInformationToFirestore(word: currentWord, wordInformation: wordInformation) {
                            print("Word information saved to Firestore for word: \(currentWord)")
                            fetchWordInformation(word: currentWord) // Fetch the word information after saving
                        }
                    } else {
                        print("Failed to fetch word information for word: \(currentWord)")
                    }
                }
            }
        }
    }

    func restartQuiz() {
        // Reset all relevant properties to restart the quiz
        quizCompleted = false
        currentQuestionIndex = 0
        compiledAnswers = []
        answer = ""
        quizViewModel.score = 0

        // ... (other relevant code)
    }
    
    func initializeAudioPlayer() {
            if let url = URL(string: urlString) {
                audioPlayer = AVPlayer(url: url)
            }
        }

    func playAudio() {
        if let audioPlayer = audioPlayer {
            // Seek to the beginning of the audio and play it
            audioPlayer.seek(to: .zero)
            audioPlayer.play()
        }
    }

    func fetchWordInformation(word: String) {
        let cleanedWord = word.replacingOccurrences(of: ":1", with: "") // Remove ":1" if present
        let db = Firestore.firestore()
        let collectionRef = db.collection("JSON")
        let documentRef = collectionRef.document(cleanedWord)
        documentRef.getDocument { (snapshot, error) in
            if let error = error {
                print("Error retrieving document: \(error.localizedDescription)")
            } else if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.wordInformation = data
                }
            } else {
                print("Document does not exist for word: \(cleanedWord)")
            }
        }
    }

    func saveWordInformationToFirestore(word: String, wordInformation: [String: Any], completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let collectionRef = db.collection("JSON")
        let documentRef = collectionRef.document(word)
        documentRef.setData(wordInformation) { error in
            if let error = error {
                print("Error saving word information to Firestore: \(error.localizedDescription)")
            } else {
                completion()
            }
        }
    }

    func checkWordExistsInFirestore(word: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let collectionRef = db.collection("JSON")
        let documentRef = collectionRef.document(word)
        documentRef.getDocument { (snapshot, error) in
            if let error = error {
                print("Error retrieving document: \(error.localizedDescription)")
                completion(false)
            } else if snapshot?.exists == true {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    func fetchWordInformationFromAPI(word: String, completion: @escaping ([String: Any]?) -> Void) {
        let apiUrl = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/\(word)?key=040ad1ae-8561-426d-a44a-ff7fbe250176"

        if let url = URL(string: apiUrl) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    completion(nil) // Notify the completion closure of the failure
                } else if let data = data {
                    do {
                        if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                            // Check if the array is not empty
                            if let firstObject = jsonArray.first {
                                // Create a dictionary to store the word information
                                var wordInformation: [String: Any] = [:]

                                // Extract the desired information for the current word
                                if let meta = firstObject["meta"] as? [String: Any] {
                                    wordInformation["id"] = meta["id"]
                                    wordInformation["section"] = meta["section"]
                                    wordInformation["offensive"] = meta["offensive"]
                                }

                                if let hwi = firstObject["hwi"] as? [String: Any] {
                                    wordInformation["headword"] = hwi["hw"]
                                    // Extract additional fields from the hwi object
                                    if let prsArray = hwi["prs"] as? [[String: Any]] {
                                        var pronunciations: [String] = []
                                        for prs in prsArray {
                                            if let mw = prs["mw"] as? String {
                                                pronunciations.append(mw)
                                            }
                                            if let sound = prs["sound"] as? [String: Any] {
                                                if let audio = sound["audio"] as? String {
                                                    pronunciations.append(audio)
                                                }
                                            }
                                            // Extract any additional fields you need from the prs object
                                        }
                                        wordInformation["pronunciations"] = pronunciations
                                    }
                                }

                                if let fl = firstObject["fl"] as? String {
                                    wordInformation["partOfSpeech"] = fl
                                }

                                if let shortDefArray = firstObject["shortdef"] as? [String] {
                                    if let firstShortDef = shortDefArray.first {
                                        wordInformation["shortDefinition"] = firstShortDef
                                    }
                                }

                                completion(wordInformation) // Pass the word information to the completion closure
                                return
                            }
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                }

                completion(nil) // Notify the completion closure of the failure
            }
            task.resume()
        } else {
            completion(nil) // Notify the completion closure of the failure
        }
    }

}

struct ProgressBarSpanish: View {
    let currentQuestion: Int
    let totalQuestions: Int
    
    var body: some View {
        VStack {
            Text("Question \(currentQuestion + 1) of \(totalQuestions)")
            ProgressView(value: Double(currentQuestion) + 1, total: Double(totalQuestions))
        }
        .padding()
    }
}

struct SpanishQuizView_Previews: PreviewProvider {
    static var previews: some View {
        SpanishQuizView()
            .environmentObject(AuthViewModel()) // Provide the AuthViewModel environment object
    }
}

    




