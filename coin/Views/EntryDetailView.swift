import SwiftUI
import MessageUI

struct EntryDetailView: View {
    @State private var recipientName: String = ""
    @State private var recipientEmail: String = ""
    @State private var showMailComposer: Bool = false
    @State private var sharedAt: Date? = nil
    @State private var shareCount: Int = 0

    var body: some View {
        VStack {
            // Display COIN fields in read-only glass cards
            GlassCardView(title: "Field 1", content: "Value 1")
            GlassCardView(title: "Field 2", content: "Value 2")
            GlassCardView(title: "Field 3", content: "Value 3")
            GlassCardView(title: "Field 4", content: "Value 4")

            // Display recipient info if present
            if !recipientName.isEmpty && !recipientEmail.isEmpty {
                Text("Recipient: \(recipientName) <\(recipientEmail)>")
            }

            // Display shared status
            Text(sharedAt == nil ? "Not shared yet" : "Shared on \(sharedAt!) to \(recipientEmail)")

            HStack {
                Button(action: { editEntry() }) {
                    Text("Edit")
                }
                Button(action: { showMailComposer.toggle() }) {
                    Text("Share")
                }
            }
        }
        .sheet(isPresented: $showMailComposer) {
            RecipientPromptSheet(recipientName: $recipientName, recipientEmail: $recipientEmail, onShare: { share() })
        }
    }

    private func editEntry() {
        // Implement edit functionality
    }

    private func share() {
        // Implement share functionality
        // Use MFMailComposeViewController to send email
        // Call this function when the email is sent successfully
        handleEmailSent()
    }

    private func handleEmailSent() {
        sharedAt = Date()
        shareCount += 1
        // Persist changes to sharedAt and shareCount
    }

    private func handleEmailFailed() {
        // Log attempted share if necessary
    }
}

struct GlassCardView: View {
    var title: String
    var content: String

    var body: some View {
        VStack {
            Text(title).font(.headline)
            Text(content).font(.subheadline)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RecipientPromptSheet: View {
    @Binding var recipientName: String
    @Binding var recipientEmail: String
    var onShare: () -> Void

    var body: some View {
        Form {
            TextField("Name", text: $recipientName)
            TextField("Email", text: $recipientEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .onChange(of: recipientEmail) { newValue in
                    // Basic email validation
                    if !isValidEmail(newValue) {
                        // Handle invalid email
                    }
                }
            Button("Share") {
                onShare()
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        // Basic email validation logic
        return email.contains("@") && email.contains(".")
    }
}