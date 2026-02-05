import SwiftUI
import SwiftData
import UIKit
import PDFKit
import MessageUI

struct EntryDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.colorScheme) private var colorScheme
    
    let entry: FeedbackEntry

    @Query private var shareEvents: [ShareEvent]
    
    @State private var isEditing = false
    @State private var recipientName = ""
    @State private var recipientEmail = ""
    @State private var showRecipientPrompt = false
    @State private var showEmailComposer = false
    @State private var showMailError = false
    @State private var showInvalidEmailAlert = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showPaywall = false

    init(entry: FeedbackEntry) {
        self.entry = entry
        let entryId = entry.id.uuidString
        _shareEvents = Query(
            filter: #Predicate<ShareEvent> { $0.entryId == entryId },
            sort: [SortDescriptor(\.sharedAt, order: .reverse)]
        )
    }
    
    var hasExistingRecipient: Bool {
        if let email = entry.recipientEmail, !email.isEmpty {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Recipient Information at the top
                    if let email = entry.recipientEmail, !email.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                Text("Recipient Information")
                                    .font(.headline)
                            }
                            .foregroundColor(AppColors.primaryAccent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if let name = entry.recipientName, !name.isEmpty {
                                    Text("Name: \(name)")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                                }
                                Text("Email: \(email)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            }
                        }
                        .modifier(FluidCardModifier())
                    }
                    
                    // COIN worksheet layout
                    CoinWorksheetView(
                        context: entry.context,
                        observation: entry.observation,
                        impact: entry.impact,
                        nextSteps: entry.nextSteps
                    )
                    
                    // Share history (most recent first)
                    if !shareEvents.isEmpty || entry.sharedAt != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "paperplane.fill")
                                Text("Share History")
                                    .font(.headline)
                            }
                            .foregroundColor(AppColors.sharedAccent)

                            VStack(alignment: .leading, spacing: 6) {
                                if !shareEvents.isEmpty {
                                    ForEach(shareEvents, id: \.persistentModelID) { event in
                                        Text(shareEventLine(event))
                                            .font(.caption)
                                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                                    }
                                } else if let sharedAt = entry.sharedAt {
                                    Text("Last shared: \(sharedAt.formatted())")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                                }
                            }
                        }
                        .modifier(FluidCardModifier())
                    }
                    
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Feedback Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { 
                        isEditing = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: {
                        // Check if user is pro before allowing share
                        if !purchaseManager.isProUser {
                            showPaywall = true
                        } else if hasExistingRecipient {
                            // Reuse existing recipient info
                            recipientName = entry.recipientName ?? ""
                            recipientEmail = entry.recipientEmail ?? ""
                            recordShareEventIfPossible()
                            checkAndShowEmailComposer()
                        } else {
                            // Ask for recipient info
                            showRecipientPrompt = true
                        }
                    }) {
                        Label("Share via Email", systemImage: "envelope")
                    }
                    Button(role: .destructive, action: { deleteEntry() }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            CoinEditorView(entry: entry)
        }
        .sheet(isPresented: $showRecipientPrompt) {
            RecipientPromptSheet(
                recipientName: $recipientName,
                recipientEmail: $recipientEmail,
                onShare: { 
                    entry.markAsShared(to: recipientEmail, recipientName: recipientName)
                    modelContext.insert(ShareEvent(entryId: entry.id.uuidString, recipientEmail: recipientEmail, recipientName: recipientName))
                    try? modelContext.save()
                    showRecipientPrompt = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkAndShowEmailComposer()
                    }
                }
            )
        }
        .sheet(isPresented: $showEmailComposer) {
            MailComposerSheet(
                entry: entry,
                recipientEmail: recipientEmail,
                recipientName: recipientName,
                isPresented: $showEmailComposer
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchaseManager: purchaseManager)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
        }
        .alert("Mail Not Available", isPresented: $showMailError) {
            Button("Copy Email") {
                UIPasteboard.general.string = shareEmailBody()
            }
            Button("Share PDF") {
                prepareShareItems()
                showShareSheet = true
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mail is not configured or not available on this device. You can copy the email text or share the PDF instead.")
        }
        .alert("Invalid Email", isPresented: $showInvalidEmailAlert) {
            Button("Edit Recipient") {
                showRecipientPrompt = true
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("The recipient email address is missing or invalid. Please update it before sending.")
        }
    }

    private func checkAndShowEmailComposer() {
#if targetEnvironment(simulator)
        showMailError = true
#else
        guard isValidEmail(recipientEmail) else {
            showInvalidEmailAlert = true
            return
        }
        if MFMailComposeViewController.canSendMail() {
            showEmailComposer = true
        } else {
            showMailError = true
        }
#endif
    }

    private func shareEventLine(_ event: ShareEvent) -> String {
        let date = event.sharedAt.formatted(date: .abbreviated, time: .shortened)
        let namePart = event.recipientName.isEmpty ? "" : "\(event.recipientName) "
        return "\(date) — \(namePart)<\(event.recipientEmail)>"
    }

    private func recordShareEventIfPossible() {
        guard isValidEmail(recipientEmail) else { return }
        entry.markAsShared(to: recipientEmail, recipientName: recipientName)
        modelContext.insert(ShareEvent(entryId: entry.id.uuidString, recipientEmail: recipientEmail, recipientName: recipientName))
        try? modelContext.save()
    }

    private func shareEmailBody() -> String {
        let subject = "COIN Feedback: \(entry.context)"
        let body = """
COIN Feedback Entry:

Context:
\(entry.context)

Observation:
\(entry.observation)

Impact:
\(entry.impact)

Next Steps:
\(entry.nextSteps)

---
Sent from COIN Feedback App
"""
        return """
To: \(recipientEmail)
Subject: \(subject)

\(body)
"""
    }

    private func prepareShareItems() {
        var items: [Any] = [shareEmailBody()]
        if let pdfURL = createTempPDFURL() {
            items.append(pdfURL)
        }
        shareItems = items
    }

    private func createTempPDFURL() -> URL? {
        guard let pdfData = generatePDF() else {
            return nil
        }
        let filename = "COIN_Feedback_\(UUID().uuidString).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try pdfData.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
    
    private func generatePDF() -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 562
            let contentWidth = rightMargin - leftMargin
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "COIN Feedback"
            title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Recipient Information (at top)
            if let name = entry.recipientName, !name.isEmpty,
               let email = entry.recipientEmail, !email.isEmpty {
                let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemBlue
                ]
                "Recipient Information".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionTitleAttributes)
                yPosition += 25
                
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.darkGray
                ]
                "Name: \(name)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 20
                "Email: \(email)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 35
            }
            
            // Helper function to draw sections
            func drawSection(title: String, content: String) {
                let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemBlue
                ]
                title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionTitleAttributes)
                yPosition += 25
                
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                
                let attributedString = NSAttributedString(
                    string: content,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black,
                        .paragraphStyle: paragraphStyle
                    ]
                )
                
                let textRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: 1000)
                let size = attributedString.boundingRect(
                    with: CGSize(width: contentWidth, height: 1000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                
                attributedString.draw(in: textRect)
                yPosition += size.height + 25
            }
            
            // COIN Sections
            drawSection(title: "Context", content: entry.context)
            drawSection(title: "Observation", content: entry.observation)
            drawSection(title: "Impact", content: entry.impact)
            drawSection(title: "Next Steps", content: entry.nextSteps)
            
            // Share History (most recent first)
            if !shareEvents.isEmpty || entry.sharedAt != nil {
                yPosition += 10
                let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemGreen
                ]
                "Share History".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionTitleAttributes)
                yPosition += 25

                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.darkGray
                ]

                if !shareEvents.isEmpty {
                    for event in shareEvents {
                        let date = event.sharedAt.formatted(date: .abbreviated, time: .shortened)
                        let namePart = event.recipientName.isEmpty ? "" : "\(event.recipientName) "
                        let line = "\(date) — \(namePart)<\(event.recipientEmail)>"
                        line.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
                        yPosition += 18
                    }
                } else if let sharedAt = entry.sharedAt {
                    "Last shared: \(sharedAt.formatted(date: .abbreviated, time: .shortened))"
                        .draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
                }
            }
        }
        
        return data
    }
    
    private func deleteEntry() {
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}

struct CoinWorksheetView: View {
    let context: String
    let observation: String
    let impact: String
    let nextSteps: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MY FEEDBACK")
                .font(.system(size: 20, weight: .bold))
                .tracking(1.2)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.primaryAccent)
                    .padding(.top, 2)
                Text("Use the COIN model to outline how you will approach your feedback conversation.")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            VStack(spacing: 0) {
                CoinWorksheetRow(letter: "C", title: "Context", content: context)
                Divider().opacity(0.5)
                CoinWorksheetRow(letter: "O", title: "Observation", content: observation)
                Divider().opacity(0.5)
                CoinWorksheetRow(letter: "I", title: "Impact", content: impact)
                Divider().opacity(0.5)
                CoinWorksheetRow(letter: "N", title: "Next Steps", content: nextSteps)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground).opacity(colorScheme == .dark ? 0.22 : 0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08), lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground).opacity(colorScheme == .dark ? 0.20 : 0.70))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
            radius: 18,
            x: 0,
            y: 10
        )
    }
}

struct CoinWorksheetRow: View {
    let letter: String
    let title: String
    let content: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack {
                Text(letter)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.primaryAccent)
            }
            .frame(minWidth: 36, maxWidth: 36, maxHeight: .infinity, alignment: .center)
            .background(
                AppColors.primaryAccent.opacity(colorScheme == .dark ? 0.18 : 0.12)
            )
            
            Divider().opacity(0.35)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                Text(content)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: 72, alignment: .center)
    }
}

struct FluidCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBackground).opacity(colorScheme == .dark ? 0.20 : 0.70))
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                radius: 18,
                x: 0,
                y: 10
            )
    }
}

struct RecipientPromptSheet: View {
    @Binding var recipientName: String
    @Binding var recipientEmail: String
    var onShare: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient Information") {
                    TextField("Name", text: $recipientName)
                    TextField("Email", text: $recipientEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Share Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        if isValidEmail(recipientEmail) {
                            dismiss()
                            // Wait for dismissal to complete
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onShare()
                            }
                        }
                    }
                    .disabled(recipientName.isEmpty || recipientEmail.isEmpty || !isValidEmail(recipientEmail))
                }
            }
        }
    }
}

// MARK: - Activity (Share) Sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

func isValidEmail(_ email: String) -> Bool {
    let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
    return predicate.evaluate(with: email)
}

// MARK: - Mail Composer Sheet
struct MailComposerSheet: UIViewControllerRepresentable {
    let entry: FeedbackEntry
    let recipientEmail: String
    let recipientName: String
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.mailComposeController == nil else { return }
        
        if let mailComposer = createMailComposer(context: context) {
            context.coordinator.mailComposeController = mailComposer
            DispatchQueue.main.async {
                uiViewController.present(mailComposer, animated: true)
            }
        } else {
            isPresented = false
        }
    }
    
    private func createMailComposer(context: Context) -> MFMailComposeViewController? {
        guard MFMailComposeViewController.canSendMail() else {
            return nil
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        // Set recipient
        if !recipientEmail.isEmpty {
            mailComposer.setToRecipients([recipientEmail])
        }
        
        // Set subject
        let subject = "COIN Feedback: \(entry.context)"
        mailComposer.setSubject(subject)
        
        // Set body
        let greeting = recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Hello,"
            : "Dear \(recipientName),"
        let body = """
        \(greeting)
        
        Please find attached the COIN feedback document.
        
        Best regards
        """
        mailComposer.setMessageBody(body, isHTML: false)
        
        // Generate and attach PDF
        if let pdfData = generatePDF(for: entry, recipientName: recipientName, recipientEmail: recipientEmail) {
            mailComposer.addAttachmentData(
                pdfData,
                mimeType: "application/pdf",
                fileName: "COIN_Feedback_\(Date().formatted(date: .abbreviated, time: .omitted)).pdf"
            )
        }
        
        return mailComposer
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        var mailComposeController: MFMailComposeViewController?
        
        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            mailComposeController = nil
            isPresented = false
        }
    }
    
    private func generatePDF(for entry: FeedbackEntry, recipientName: String, recipientEmail: String) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 562
            let contentWidth = rightMargin - leftMargin
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "COIN Feedback".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Recipient Information (at top)
            let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.systemBlue
            ]
            "Recipient Information".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionTitleAttributes)
            yPosition += 25
            
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            "Name: \(recipientName)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20
            "Email: \(recipientEmail)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 35
            
            // Helper function to draw sections
            func drawSection(title: String, content: String) {
                let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemBlue
                ]
                title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: sectionTitleAttributes)
                yPosition += 25
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                
                let attributedString = NSAttributedString(
                    string: content,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black,
                        .paragraphStyle: paragraphStyle
                    ]
                )
                
                let textRect = CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: 1000)
                let size = attributedString.boundingRect(
                    with: CGSize(width: contentWidth, height: 1000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                
                attributedString.draw(in: textRect)
                yPosition += size.height + 25
            }
            
            // COIN Sections
            drawSection(title: "Context", content: entry.context)
            drawSection(title: "Observation", content: entry.observation)
            drawSection(title: "Impact", content: entry.impact)
            drawSection(title: "Next Steps", content: entry.nextSteps)
            
            // Shared Status
            if entry.shareCount > 0, let sharedAt = entry.sharedAt {
                yPosition += 10
                let statusAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.systemGreen
                ]
                "Shared Status".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: statusAttributes)
                yPosition += 25
                
                "Shared \(entry.shareCount) time(s)".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 20
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                "Last shared: \(dateFormatter.string(from: sharedAt))".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: bodyAttributes)
            }
        }
        
        return data
    }
}

#Preview {
    EntryDetailView(entry: FeedbackEntry(
        context: "Sample context",
        observation: "Sample observation",
        impact: "Sample impact",
        nextSteps: "Sample next steps"
    ))
}
